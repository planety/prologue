import httpcore, asyncdispatch, asyncfile, mimetypes, md5, uri
import strtabs, tables, strformat, os, times, options, parseutils, json

import ./response, ./pages, ./constants
import ./cookies
from ./types import BaseType, Session, SameSite, `[]`, initSession
from ./configure import parseValue

from ./basicregex import Regex
from ./nativesettings import Settings, CtxSettings, getOrDefault, hasKey, `[]`

when defined(windows) or defined(usestd):
  import ../naive/request
else:
  import ../beast/request


type
  PathHandler* = ref object
    handler*: HandlerAsync
    middlewares*: seq[HandlerAsync]
    settings*: Settings

  Path* = object
    route*: string
    httpMethod*: HttpMethod

  # may change to flat
  Router* = ref object
    callable*: Table[Path, PathHandler]

  RePath* = object
    route*: Regex
    httpMethod*: HttpMethod

  ReRouter* = ref object
    callable*: seq[(RePath, PathHandler)]

  ReversedRouter* = StringTableRef

  Context* = ref object
    request*: Request
    response*: Response
    router*: Router
    reversedRouter*: ReversedRouter
    reRouter*: ReRouter
    size*: int
    first*: bool
    handled*: bool
    middlewares*: seq[HandlerAsync]
    session*: Session
    cleanedData*: StringTableRef
    ctxData*: StringTableRef
    settings*: Settings
    localSettings*: Settings
    ctxSettings*: CtxSettings

  AsyncEvent* = proc(): Future[void] {.closure, gcsafe.}
  SyncEvent* = proc() {.closure, gcsafe.}

  Event* = object
    case async*: bool
    of true:
      asyncHandler*: AsyncEvent
    of false:
      syncHandler*: SyncEvent

  HandlerAsync* = proc(ctx: Context): Future[void] {.closure, gcsafe.}

  ErrorHandler* = proc(ctx: Context): Future[void] {.nimcall, gcsafe.}

  ErrorHandlerTable* = TableRef[HttpCode, ErrorHandler]

  UpLoadFile* = object
    filename*: string
    body*: string

proc default404Handler*(ctx: Context) {.async.}
proc default500Handler*(ctx: Context) {.async.}


proc initUploadFile*(filename, body: string): UpLoadFile {.inline.} =
  UpLoadFile(filename: filename, body: body)

proc getUploadFile*(ctx: Context, name: string): UpLoadFile {.inline.} =
  let file = ctx.request.formParams[name]
  initUploadFile(filename = file.params["filename"], body = file.body)

proc save*(uploadFile: UpLoadFile, dir: string, filename: string,
    useDefault = false) {.inline.} =
  # TODO use time or random string as filename
  if useDefault:
    writeFile(dir / uploadFile.filename, uploadFile.body)
  writeFile(dir / filename, uploadFile.body)

proc newErrorHandlerTable*(initialSize = defaultInitialSize): ErrorHandlerTable {.inline.} =
  newTable[HttpCode, ErrorHandler](initialSize)

proc newErrorHandlerTable*(pairs: openArray[(HttpCode,
    ErrorHandler)]): ErrorHandlerTable {.inline.} =
  newTable[HttpCode, ErrorHandler](pairs)

proc newReversedRouter*(): ReversedRouter {.inline.} =
  newStringTable()

proc initEvent*(handler: AsyncEvent): Event {.inline.} =
  Event(async: true, asyncHandler: handler)

proc initEvent*(handler: SyncEvent): Event {.inline.} =
  Event(async: false, syncHandler: handler)

proc newContext*(request: Request, response: Response,
    router: Router, reversedRouter: ReversedRouter,
        reRouter: ReRouter, settings: Settings,
            ctxSettings: CtxSettings): Context {.inline.} =
  Context(request: request, response: response, router: router,
          reversedRouter: reversedRouter, reRouter: reRouter, size: 0,
          first: true,
          handled: false,
          session: initSession(data = newStringTable()),
          cleanedData: newStringTable(),
          ctxData: newStringTable(),
          settings: settings,
          localSettings: nil,
          ctxSettings: ctxSettings
    )

proc getSettings*(ctx: Context, key: string): JsonNode {.inline.} =
  if ctx.localSettings == nil:
    result = ctx.settings.getOrDefault(key)
  elif not ctx.localSettings.hasKey(key):
    result = ctx.settings.getOrDefault(key)
  else:
    result = ctx.localSettings[key]

proc handle*(ctx: Context): Future[void] {.inline.} =
  result = ctx.request.respond(ctx.response)

proc send*(ctx: Context, content: string): Future[void] {.inline.} =
  result = ctx.request.send(content)

proc respond*(ctx: Context, code: HttpCode, body: string,
  headers: HttpHeaders = newHttpHeaders()): Future[void] {.inline.} =
  result = ctx.request.respond(code, body, headers)

proc hasHeader*(request: var Request, key: string): bool {.inline.} =
  request.headers.hasKey(key)

proc setHeader*(request: var Request, key, value: string) {.inline.} =
  request.headers[key] = value

proc setHeader*(request: var Request, key: string, value: sink seq[string]) {.inline.} =
  request.headers[key] = value

proc addHeader*(request: var Request, key, value: string) {.inline.} =
  request.headers.add(key, value)

proc getCookie*(ctx: Context, key: string, default: string = ""): string {.inline.} =
  getCookie(ctx.request, key, default)

proc setCookie*(ctx: Context, key, value: string, expires = "", maxAge: Option[
    int] = none(int),
  domain = "", path = "", secure = false, httpOnly = false, sameSite = Lax) {.inline.} =
  ctx.response.setCookie(key, value, expires, maxAge, domain, path, secure,
      httpOnly, sameSite)

proc setCookie*(ctx: Context, key, value: string, expires: DateTime|Time,
    maxAge: Option[int] = none(int),
    domain = "", path = "", secure = false, httpOnly = false, sameSite = Lax) {.inline.} =
  ctx.response.setCookie(key, value, domain, expires, maxAge, path, secure,
      httpOnly, sameSite)

proc deleteCookie*(ctx: Context, key: string, path = "", domain = "") {.inline.} =
  ctx.deleteCookie(key = key, path = path, domain = domain)

proc defaultHandler*(ctx: Context) {.async.} =
  ctx.response.code = Http404

proc default404Handler*(ctx: Context) {.async.} =
  ctx.response.body = errorPage("404 Not Found!", PrologueVersion)
  ctx.response.setHeader("content-type", "text/html; charset=UTF-8")

proc default500Handler*(ctx: Context) {.async.} =
  ctx.response.body = internalServerErrorPage()
  ctx.response.setHeader("content-type", "text/html; charset=UTF-8")

proc getPostParams*(ctx: Context, key: string, default = ""): string {.inline.} =
  case ctx.request.reqMethod
  of HttpPost:
    result = ctx.request.postParams.getOrDefault(key, default)
  else:
    result = ""

proc getQueryParams*(ctx: Context, key: string, default = ""): string {.inline.} =
  result = ctx.request.queryParams.getOrDefault(key, default)

proc getPathParams*(ctx: Context, key: string): string {.inline.} =
  ctx.request.pathParams.getOrDefault(key)

proc getPathParams*[T: BaseType](ctx: Context, key: sink string,
    default: T): T {.inline.} =
  let pathParams = ctx.request.pathParams.getOrDefault(key)
  parseValue(pathParams, default)

proc setResponse*(ctx: Context, code: HttpCode, httpHeaders =
  {"Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders,
      body = "", version = HttpVer11) {.inline.} =
  ## handy to make ctx's response
  let response = initResponse(httpVersion = version, code = code,
    headers = {"Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders,
        body = body)
  ctx.response = response

proc setResponse*(ctx: Context, response: Response) {.inline.} =
  ## handy to make ctx's response
  ctx.response = response

proc multiMatch*(s: string, replacements: StringTableRef): string =
  result = newStringOfCap(s.len)
  var
    pos = 0
    tok = ""
  let
    startChar = '{'
    endChar = '}'
    sep = '/'

  while pos < s.len:
    pos += parseUntil(s, tok, startChar, pos)
    result.add tok
    if pos < s.len:
      assert s[pos-1] == sep, "The char before '{' must be '/'"
    else:
      break
    inc(pos)
    pos += parseUntil(s, tok, endChar, pos)
    inc pos
    if tok.len != 0:
      if tok in replacements:
        result.add replacements[tok]
      else:
        raise newException(ValueError, "Unexpected key")

proc multiMatch*(s: string, replacements: varargs[(string, string)]): string {.inline.} =
  multiMatch(s, replacements.newStringTable)

proc urlFor*(ctx: Context, handler: string, parameters: openArray[(string,
    string)] = @[], queryParams: openArray[(string, string)] = @[],
        usePlus = true, omitEq = true): string {.inline.} =

  ## { } can't appear in url
  if handler in ctx.reversedRouter:
    result = ctx.reversedRouter[handler]

  result = multiMatch(result, parameters)
  let queryString = encodeQuery(queryParams, usePlus, omitEq)
  if queryString.len != 0:
    result = multiMatch(result, parameters) & "?" & queryString

proc attachment*(ctx: Context, downloadName = "", charset = "utf-8") {.inline.} =
  if downloadName.len == 0:
    return

  var ext = downloadName.splitFile.ext
  if ext.len > 0:
    ext = ext[1 .. ^1]
    let mimes = ctx.ctxSettings.mimeDB.getMimetype(ext)
    if mimes.len != 0:
      ctx.response.setHeader("Content-Type", fmt"{mimes}; charset={charset}")

  ctx.response.setHeader("Content-Disposition",
      fmt"""attachment; filename="{downloadName}"""")

proc staticFileResponse*(ctx: Context, filename, root: string, mimetype = "",
    downloadName = "", charset = "utf-8", headers = newHttpHeaders()) {.async.} =
  let
    filePath = root / filename

  # exists -> have access -> can open

  var filePermission = getFilePermissions(filePath)
  if fpOthersRead notin filePermission:
    resp abort(code = Http403,
        body = "You do not have permission to access this file.",
        headers = headers)
    return

  var
    mimetype = mimetype

  if mimetype.len == 0:
    var ext = filename.splitFile.ext
    if ext.len > 0:
      ext = ext[1 .. ^1]
    mimetype = ctx.ctxSettings.mimeDB.getMimetype(ext)

  let
    info = getFileInfo(filePath)
    contentLength = info.size
    lastModified = info.lastWriteTime
    etagBase = fmt"{filename}-{lastModified}-{contentLength}"
    etag = getMD5(etagBase)

  ctx.response.headers = headers

  if mimetype.len != 0:
    ctx.response.setHeader("Content-Type", fmt"{mimetype}; {charset}")

  ctx.response.setHeader("Content-Length", $contentLength)
  ctx.response.setHeader("Last-Modified", $lastModified)
  ctx.response.setHeader("Etag", etag)

  if downloadName.len != 0:
    ctx.attachment(downloadName)

  if contentLength < 20_000_000:
    if ctx.request.hasHeader("If-None-Match") and ctx.request.headers[
        "If-None-Match"] == etag:
      await ctx.respond(Http304, "")
    else:
      let body = readFile(filePath)
      resp initResponse(HttpVer11, Http200, headers, body)
  else:
    # stream
    await ctx.respond(Http200, "", headers)
    var
      fileStream = newFutureStream[string]("staticFileResponse")
      file = openAsync(filePath, fmRead)
    defer: file.close()

    await file.readToStream(fileStream)

    while true:
      let (hasValue, value) = await fileStream.read()
      if hasValue:
        await ctx.send(value)
      else:
        break
    ctx.handled = true
