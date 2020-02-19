import httpcore, asyncdispatch, asyncfile, mimetypes, md5
import strtabs, macros, tables, strformat, os, times, options

import response, pages, constants, cookies
from types import BaseType, Session, SameSite, initSession

import regex


when not defined(production):
  import ../naive/request


type
  PathHandler* = ref object
    handler*: HandlerAsync
    middlewares*: seq[HandlerAsync]
    excludeMiddlewares*: seq[HandlerAsync]

  Path* = object
    route*: string
    httpMethod*: HttpMethod

  Router* = ref object
    callable*: Table[Path, PathHandler]

  RePath* = object
    route*: Regex
    httpMethod*: HttpMethod

  ReRouter* = ref object
    callable*: seq[(RePath, PathHandler)]

  Context* = ref object
    request*: Request
    response*: Response
    router*: Router
    reRouter*: ReRouter
    size*: int
    first*: bool
    middlewares*: seq[HandlerAsync]
    session*: Session

  AsyncEvent* = proc(): Future[void] {.closure, gcsafe.}
  SyncEvent* = proc() {.closure, gcsafe.}

  Event* = object
    case async*: bool
    of true:
      asyncHandler*: AsyncEvent
    of false:
      syncHandler*: SyncEvent
  
  HandlerAsync* = proc(ctx: Context): Future[void] {.closure, gcsafe.}

proc initEvent*(handler: AsyncEvent): Event =
  Event(async: true, asyncHandler: handler)

proc initEvent*(handler: SyncEvent): Event =
  Event(async: false, syncHandler: handler)

proc newContext*(request: Request, response: Response,
    router: Router, reRouter: ReRouter): Context {.inline.} =
  Context(request: request, response: response, router: router,
      reRouter: reRouter, size: 0, first: true, session: initSession(
          data = newStringTable()))

proc handle*(ctx: Context): Future[void] {.inline.} =
  result = ctx.request.respond(ctx.response)

proc defaultHandler*(ctx: Context) {.async.} =
  let response = error404(body = errorPage("404 Not Found!", PrologueVersion))
  await ctx.request.respond(response)

proc setHeader*(ctx: Context; key, value: string) {.inline.} =
  ctx.response.httpHeaders[key] = value

proc addHeader*(ctx: Context; key, value: string) {.inline.} =
  ctx.response.httpHeaders.add(key, value)

proc getCookie*(ctx: Context; key: string, default: string = ""): string {.inline.} =
  getCookie(ctx.request, key, default)

proc setCookie*(ctx: Context; key, value: string, expires = "", maxAge: Option[
    int] = none(int),
  domain = "", path = "", secure = false, httpOnly = false, sameSite = Lax) {.inline.} =
  ctx.response.setCookie(key, value, expires, maxAge, domain, path, secure,
      httpOnly, sameSite)

proc setCookie*(ctx: Context; key, value: string, expires: DateTime|Time,
    maxAge: Option[int] = none(int),
   domain = "", path = "", secure = false, httpOnly = false, sameSite = Lax) {.inline.} =
  ctx.response.setCookie(key, value, domain, expires, maxAge, path, secure,
      httpOnly, sameSite)

proc deleteCookie*(ctx: Context, key: string, path = "", domain = "") {.inline.} =
  ctx.deleteCookie(key = key, path = path, domain = domain)

macro getPostParams*(key: string, default = ""): string =
  var ctx = ident"ctx"

  result = quote do:
    case `ctx`.request.reqMethod
    of HttpGet:
      `ctx`.request.getParams.getOrDefault(`key`, `default`)
    of HttpPost:
      `ctx`.request.postParams.getOrDefault(`key`, `default`)
    else:
      `default`

macro getQueryParams*(key: string, default = ""): string =
  var ctx = ident"ctx"

  result = quote do:
    `ctx`.request.queryParams.getOrDefault(`key`, `default`)

macro getPathParams*(key: string): string =
  var ctx = ident"ctx"

  result = quote do:
    `ctx`.request.pathParams.getOrDefault(`key`)

macro getPathParams*[T: BaseType](key: string, default: T): T =
  var ctx = ident"ctx"

  result = quote do:
    let pathParams = `ctx`.request.pathParams.getOrDefault(`key`)
    parseValue(pathParams, `default`)

proc attachment(ctx: Context, downloadName = "", charset = "utf-8") {.inline.} =
  if downloadName == "":
    return
  
  var ext = downloadName.splitFile.ext
  if ext.len > 0:
    ext = ext[1 .. ^1]
    let mimes = ctx.request.settings.mimeDB.getMimetype(ext)
    if mimes != "":
      ctx.setHeader("Content-Type", fmt"{mimes}; charset={charset}")
    
  ctx.setHeader("Content-Disposition", fmt"""attachment; filename="{downloadName}"""")

proc staticFileResponse*(ctx: Context, fileName, root: string, mimetype = "",
    downloadName = "", charset = "utf-8", headers = newHttpHeaders()) {.async.} =
  let
    filePath = root / fileName

  # exists -> have access -> can open
  if not existsFile(filePath):
    await ctx.request.respond(error404(headers = headers))
    return

  var filePermission = getFilePermissions(filePath)
  if fpOthersRead notin filePermission:
    await ctx.request.respond(abort(status = Http403,
        body = "You do not have permission to access this file.", headers = headers))
    return

  var
    mimetype = mimetype
    download = false

  if mimetype == "":
    var ext = fileName.splitFile.ext
    if ext.len > 0:
      ext = ext[1 .. ^ 1]
    mimetype = ctx.request.settings.mimeDB.getMimetype(ext)

  let
    info = getFileInfo(filePath)
    contentLength = info.size
    lastModified = info.lastWriteTime
    etagBase = fmt"{fileName}-{lastModified}-{contentLength}"
    etag = getMD5(etagBase)

  ctx.response.httpHeaders = headers
  
  if mimetype != "":
    ctx.setHeader("Content-Type", fmt"{mimetype}; {charset}")

  ctx.setHeader("Content-Length", $contentLength)
  ctx.setHeader("Last-Modified", $lastModified)
  ctx.setHeader("Etag", etag)

  if downloadName != "":
    ctx.attachment(downloadName)
    download = true


  if contentLength < 20_000_000:
    # if ctx.request.headers.hasKey("If-None-Match") and ctx.request.headers[
    #     "If-None-Match"] == etag and download == true:
      # await ctx.request.respond(Http304, "")
    # else:
    let body = readFile(filePath)
    await ctx.request.respond(Http200, body, headers)
  else:
    await ctx.request.respond(Http200, "", headers)
    var
      fileStream = newFutureStream[string]("staticFileResponse")
      file = openAsync(filePath, fmRead)
    defer: file.close()

    await file.readToStream(fileStream)

    while true:
      let (hasValue, value) = await fileStream.read()
      if hasValue:
        await ctx.request.send(value)
      else:
        break
