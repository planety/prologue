# Copyright 2020 Zeshen Xing
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import mimetypes, md5, uri
import strtabs, tables, strformat, os, times, options, parseutils, json

import asyncdispatch
import ./response, ./pages
import ./httpcore/httplogue

from ./types import BaseType, Session, `[]`, initSession
from ./configure import parseValue
from ./httpexception import AbortError, RouteError, DuplicatedRouteError

import ./basicregex
from ./nativesettings import Settings, LocalSettings, CtxSettings, getOrDefault, hasKey, `[]`

import ./request

import cookiejar

import strutils, critbits

when defined(usestd):
  import asyncfile
else:
  import streams


type
  PathHandler* = ref object
    handler*: HandlerAsync
    middlewares*: seq[HandlerAsync]
    settings*: Settings

  Path* = object
    route*: string
    httpMethod*: HttpMethod

  # # may change to flat
  # Router* = ref object
  #   callable*: Table[Path, PathHandler]

  RePath* = object
    route*: Regex
    httpMethod*: HttpMethod

  ReRouter* = ref object
    callable*: seq[(RePath, PathHandler)]

  ReversedRouter* = StringTableRef

  GlobalScope* = ref object
    router*: Router
    reversedRouter*: ReversedRouter
    reRouter*: ReRouter
    appData*: StringTableRef
    settings*: Settings
    ctxSettings*: CtxSettings

  Context* = ref object
    request*: Request
    response*: Response
    handled*: bool
    session*: Session
    ctxData*: StringTableRef
    localSettings*: Settings
    gScope: GlobalScope
    middlewares: seq[HandlerAsync]
    size: int8
    first: bool

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

  UploadFile* = object
    filename*: string
    body*: string


  PatternMatchingType* = enum ## Kinds of elements that may appear in a mapping
    ptrnWildcard
    ptrnParam
    ptrnText

  # Structures for setting up the mappings
  BasePatternNode* = object of RootObj ## A token within a URL to be mapped. The URL is broken into 'knots' that make up a 'rope' (``seq[BasePatternNode]``)
    isGreedy*: bool
    case kind*: PatternMatchingType
    of ptrnParam, ptrnText:
      value*: string
    of ptrnWildcard:
      discard

  # Structures for holding fully parsed mappings
  PatternNode* = object of BasePatternNode ## A node within a routing tree, usually constructed from a ``BasePatternNode``
    case isLeaf*: bool #a leaf node is one with no children
    of true:
      discard
    of false:
      children*: seq[PatternNode]

    case isTerminator*: bool # a terminator is a node that can be considered a mapping on its own, matching could stop at this node or continue. If it is not a terminator, matching can only continue
    of true:
      handler*: PathHandler
    of false:
      discard

  # Router Structures
  Router* = ref object ## Container that holds HTTP mappings to handler functions
    data*: CritBitTree[PatternNode]


proc default404Handler*(ctx: Context) {.async.}
proc default500Handler*(ctx: Context) {.async.}


func gScope*(ctx: Context): lent GlobalScope =
  ## Gets the gScope attribute of Context.
  ctx.gScope

func size*(ctx: Context): int8 =
  ## Internal function. Do not use.
  ctx.size

func incSize*(ctx: Context, num = 1) =
  ## Internal function. Do not use.
  inc(ctx.size, num)

func first*(ctx: Context): bool =
  ## Internal function. Do not use.
  ctx.first

proc `first=`*(ctx: Context, first: bool) =
  ## Internal function. Do not use.
  ctx.first = first

func middlewares*(ctx: Context): lent seq[HandlerAsync] =
  ## Internal function. Do not use.
  ctx.middlewares

proc `middlewares=`*(ctx: Context, middlewares: seq[HandlerAsync]) =
  ## Internal function. Do not use.
  ctx.middlewares = middlewares

proc addMiddlewares*(ctx: Context, middleware: HandlerAsync) {.inline.} =
  ## Internal function. Do not use.
  ctx.middlewares.add(middleware)

proc addMiddlewares*(ctx: Context, middleware: seq[HandlerAsync]) {.inline.} =
  ## Internal function. Do not use.
  ctx.middlewares.add(middleware)

func initUploadFile*(filename, body: string): UpLoadFile =
  ## Initiates a UploadFile.
  UploadFile(filename: filename, body: body)

func getUploadFile*(ctx: Context, name: string): UpLoadFile {.inline.} =
  ## Gets the UploadFile from request.
  let file = ctx.request.formParams[name]
  initUploadFile(filename = file.params.getOrDefault("filename"), body = file.body)

proc save*(uploadFile: UpLoadFile, dir: string, filename = "") {.inline.} =
  ## Saves the UploadFile to ``dir``.
  if not dirExists(dir):
    raise newException(OSError, "Dir doesn't exist.")
  if filename.len == 0:
    writeFile(dir / uploadFile.filename, uploadFile.body)
  else:
    writeFile(dir / filename, uploadFile.body)

proc newErrorHandlerTable*(initialSize = defaultInitialSize): ErrorHandlerTable =
  ## Creates a new error handler table.
  newTable[HttpCode, ErrorHandler](initialSize)

proc newErrorHandlerTable*(pairs: openArray[(HttpCode,
                           ErrorHandler)]): ErrorHandlerTable =
  ## Creates a new error handler table.
  newTable[HttpCode, ErrorHandler](pairs)

func newReversedRouter*(): ReversedRouter =
  ## Creates a new reversed router table.
  newStringTable(mode = modeCaseSensitive)

func initEvent*(handler: AsyncEvent): Event =
  ## Initializes a new asynchronous event. 
  Event(async: true, asyncHandler: handler)

func initEvent*(handler: SyncEvent): Event =
  ## Initializes a new synchronous event. 
  Event(async: false, syncHandler: handler)

func newContext*(request: Request, response: Response,
                 gScope: GlobalScope): Context =
  ## Creates a new Context.
  Context(request: request, response: response,
          handled: false,
          ctxData: newStringTable(mode = modeCaseSensitive),
          localSettings: nil,
          gScope: gScope,
          size: 0, first: true,
    )

func getSettings*(ctx: Context, key: string): JsonNode {.inline.} =
  ## Get context.settings(First lookup localSettings then lookup globalSettings).
  if ctx.localSettings == nil:
    result = ctx.gScope.settings.getOrDefault(key)
  elif not ctx.localSettings.hasKey(key):
    result = ctx.gScope.settings.getOrDefault(key)
  else:
    result = ctx.localSettings[key]

proc respond*(ctx: Context): Future[void] {.inline.} =
  ## Sends response to the client generating from `ctx.response`.
  result = ctx.request.respond(ctx.response)

proc respond*(
  ctx: Context, code: HttpCode, body: string,
  headers: ResponseHeaders
): Future[void] {.inline.} =
  ## Sends response to the client generating from `code`, `body` and `headers`.
  result = ctx.request.respond(code, body, headers)

proc send*(ctx: Context, content: string): Future[void] {.inline.} =
  ## Sends content to the client.
  result = ctx.request.send(content)

func hasHeader*(request: Request, key: string): bool {.inline.} =
  ## Returns true if key is in `request.headers`.
  request.headers.hasKey(key)

func getHeader*(request: Request, key: string): seq[string] {.inline.} =
  ## Retrieves value of `request.headers[key]`.
  seq[string](request.headers[key])

func getHeaderOrDefault*(request: Request, key: string, default = @[""]): seq[string] {.inline.} =
  ## Retrieves value of `request.headers[key]`. Otherwise `default` will be returned.
  if request.headers.hasKey(key):
    result = getHeader(request, key)
  else:
    result = default

func setHeader*(request: var Request, key, value: string) {.inline.} =
  ## Inserts a (key, value) pair into `request.headers`.
  request.headers[key] = value

func setHeader*(request: var Request, key: string, value: seq[string]) {.inline.} =
  ## Inserts a (key, value) pair into `request.headers`.
  request.headers[key] = value

func addHeader*(request: var Request, key, value: string) {.inline.} =
  ## Appends value to the existing key in `request.headers`.
  request.headers.add(key, value)

func getCookie*(ctx: Context, key: string, default = ""): string {.inline.} =
  ## Gets the value of `ctx.request.cookies[key]` if key is in cookies. Otherwise, the `default`
  ## value will be returned.
  getCookie(ctx.request, key, default)

proc setCookie*(ctx: Context, key, value: string, expires = "", 
                maxAge: Option[int] = none(int), domain = "", 
                path = "", secure = false, httpOnly = false, sameSite = Lax) {.inline.} =
  ## Sets Cookie for Response.
  ctx.response.setCookie(key, value, expires, maxAge, domain, path, secure,
      httpOnly, sameSite)

proc setCookie*(ctx: Context, key, value: string, expires: DateTime|Time,
                maxAge: Option[int] = none(int), domain = "", 
                path = "", secure = false, httpOnly = false, sameSite = Lax) {.inline.} =
  ## Sets Cookie for Response.
  ctx.response.setCookie(key, value, domain, expires, maxAge, path, secure,
      httpOnly, sameSite)

proc deleteCookie*(ctx: Context, key: string, path = "", domain = "") {.inline.} =
  ## Deletes Cookie from Response.
  ctx.response.deleteCookie(key = key, path = path, domain = domain)

proc defaultHandler*(ctx: Context) {.async.} =
  ## Default handler with HttpCode 404. 
  ctx.response.code = Http404
  ctx.response.body.setLen(0)

proc default404Handler*(ctx: Context) {.async.} =
  ## Default 404 pages.
  ctx.response.body = errorPage("404 Not Found!")
  ctx.response.setHeader("content-type", "text/html; charset=UTF-8")

proc default500Handler*(ctx: Context) {.async.} =
  ## Default 500 pages.
  ctx.response.body = internalServerErrorPage()
  ctx.response.setHeader("content-type", "text/html; charset=UTF-8")

func getPostParams*(ctx: Context, key: string, default = ""): string {.inline.} =
  ## Gets the parameters by HttpPost.
  case ctx.request.reqMethod
  of HttpPost:
    result = ctx.request.postParams.getOrDefault(key, default)
  else:
    result = ""

func getQueryParams*(ctx: Context, key: string, default = ""): string {.inline.} =
  ## Gets the query strings(for example, "www.google.com/hello?name=12", `name=12`).
  result = ctx.request.queryParams.getOrDefault(key, default)

func getPathParams*(ctx: Context, key: string): string {.inline.} =
  ## Gets the route parameters(for example, "/hello/{name}").
  ctx.request.pathParams.getOrDefault(key)

func getPathParams*[T: BaseType](ctx: Context, key: string,
                    default: T): T {.inline.} =
  ## Gets the route parameters(for example, "/hello/{name}").
  let pathParams = ctx.request.pathParams.getOrDefault(key)
  parseValue(pathParams, default)

func getFormParams*(ctx: Context, key: string, default = ""): string {.inline.} =
  ## Gets the contents of the form if key exists. Otherwise `default` will be returned.
  ## If you need the filename of the form, use `getUploadFile` instead.
  if key in ctx.request.formParams.data:
    result = ctx.request.formParams[key].body
  else:
    result = default

proc setResponse*(ctx: Context, code: HttpCode,
                  body = "", version = HttpVer11) {.inline.} =
  ## Handy to make the response of `ctx`.
  ctx.response.httpVersion = version
  ctx.response.code = code
  ctx.response.body = body

proc setResponse*(ctx: Context, response: Response) {.inline.} =
  ## Handy to make the response of `ctx`.
  ctx.response = response

proc multiMatch(s: string, replacements: StringTableRef): string =
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
      doAssert s[pos - 1] == sep, "The char before '{' must be '/'"
    else:
      break
    inc pos
    pos += parseUntil(s, tok, endChar, pos)
    inc pos
    if tok.len != 0:
      if tok in replacements:
        result.add replacements[tok]
      else:
        raise newException(ValueError, "Unexpected key")

func multiMatch(s: string, replacements: varargs[(string, string)]): string {.inline.} =
  multiMatch(s, replacements.newStringTable)

func urlFor*(ctx: Context, handler: string, parameters: openArray[(string,
             string)] = @[], queryParams: openArray[(string, string)] = @[],
             usePlus = true, omitEq = true): string {.inline.} =
  ## Returns the corresponding name of the handler.
  ## Notes that `{` and `}` can't appear in url
  if handler in ctx.gScope.reversedRouter:
    result = ctx.gScope.reversedRouter[handler]

  result = multiMatch(result, parameters)
  let queryString = encodeQuery(queryParams, usePlus, omitEq)
  if queryString.len != 0:
    result = multiMatch(result, parameters) & "?" & queryString

func abortExit*(ctx: Context, code = Http401, body = "",
                headers = initResponseHeaders(),
                version = HttpVer11) {.inline.} =
  ## Abort the program. It raises `AbortError`.
  ctx.response = abort(code, body, headers, version)
  raise newException(AbortError, "abort exit")

proc attachment*(ctx: Context, downloadName = "", charset = "utf-8") {.inline.} =
  ## `attachment` is used to specify the file which will be downloaded.
  if downloadName.len == 0:
    return

  var ext = downloadName.splitFile.ext
  if ext.len > 0:
    ext = ext[1 .. ^1]
    let mimes = ctx.gScope.ctxSettings.mimeDB.getMimetype(ext)
    if mimes.len != 0:
      ctx.response.setHeader("Content-Type", fmt"{mimes}; charset={charset}")

  ctx.response.setHeader("Content-Disposition",
                          &"attachment; filename=\"{downloadName}\"")


proc staticFileResponse*(ctx: Context, filename, dir: string, mimetype = "",
                         downloadName = "", charset = "utf-8", bufSize = 40960,
                         headers = initResponseHeaders()) {.async.} =  
  ## Serves static files.
  let
    filePath = dir / filename

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
    mimetype = ctx.gScope.ctxSettings.mimeDB.getMimetype(ext)

  let
    info = getFileInfo(filePath)
    contentLength = info.size
    lastModified = info.lastWriteTime
    etagBase = fmt"{filename}-{lastModified}-{contentLength}"
    etag = getMD5(etagBase)

  ctx.response.headers = headers

  if mimetype.len != 0:
    ctx.response.setHeader("Content-Type", fmt"{mimetype}; {charset}")

  ctx.response.setHeader("Last-Modified", $lastModified)
  ctx.response.setHeader("Etag", etag)

  if downloadName.len != 0:
    ctx.attachment(downloadName)

  if contentLength < 10_000_000:
    if ctx.request.hasHeader("If-None-Match") and ctx.request.headers[
        "If-None-Match"] == etag:
      await ctx.respond(Http304, "", initResponseHeaders())
      ctx.handled = true
    else:
      ctx.response.body = readFile(filePath)
  else:
    ctx.response.setHeader("Content-Length", $contentLength)
    await ctx.respond(Http200, "", ctx.response.headers)

    when defined(usestd):
      var file = openAsync(filePath, fmRead)

      while true:
        let value = await file.read(bufSize)

        if value.len > 0:
          await ctx.send(value)
        else:
          break

      file.close()
    else:
      ## TODO asyncfile doesn't work with httpx
      var file = newFileStream(filePath)
      while true:
        let value = file.readStr(bufSize)

        if value.len > 0:
          await ctx.send(value)
        else:
          break

      file.close()

    ctx.handled = true
