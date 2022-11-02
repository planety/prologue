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

import std/[mimetypes, md5, uri, strutils, critbits, 
            asyncfile, asyncdispatch,strtabs, tables, strformat, 
            os, times, options, parseutils, json]

import ./response, ./pages, ./basicregex, ./request, ./httpcore/httplogue
import ./types
from ./configure import parseValue
from ./httpexception import AbortError, RouteError, DuplicatedRouteError
from ./nativesettings import Settings, CtxSettings, getOrDefault, hasKey, `[]`

import pkg/cookiejar


type
  PathHandler* = ref object
    handler*: HandlerAsync
    middlewares*: seq[HandlerAsync]

  Path* = object
    route*: string
    httpMethod*: HttpMethod

  RePath* = object
    route*: Regex
    httpMethod*: HttpMethod

  ReRouter* = ref object
    callable*: seq[(RePath, PathHandler)]

  ReversedRouter* = StringTableRef

  GlobalScope* = ref object   ## Contains global data passed to `Context`.
    router*: Router
    reversedRouter*: ReversedRouter
    reRouter*: ReRouter
    appData*: StringTableRef
    settings*: Settings
    ctxSettings*: CtxSettings

  Context* = ref object of RootObj
    request*: Request
    response*: Response
    handled*: bool
    session*: Session
    ctxData*: StringTableRef
    gScope: GlobalScope
    middlewares: seq[HandlerAsync]
    size: int8
    first: bool

  AsyncEvent* = proc(): Future[void] {.closure, gcsafe.}
  SyncEvent* = proc() {.closure, gcsafe.}

  Event* = object      ## `startup` or `shutdown` event which is executed once.
    case async*: bool
    of true:
      asyncHandler*: AsyncEvent
    of false:
      syncHandler*: SyncEvent

  HandlerAsync* = proc(ctx: Context): Future[void] {.closure, gcsafe.}

  ErrorHandler* = proc(ctx: Context): Future[void] {.nimcall, gcsafe.}

  ErrorHandlerTable* = TableRef[HttpCode, ErrorHandler]

  UploadFile* = object  ## Contains `filename` and `body` of a file uploaded by users.
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


proc default404Handler*(ctx: Context): Future[void]
proc default500Handler*(ctx: Context): Future[void]


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

proc execEvent*(event: Event) {.inline.} =
  if event.async:
    waitFor event.asyncHandler()
  else:
    event.syncHandler()

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

proc init*(ctx: Context, request: Request, response: Response,
                 gScope: GlobalScope) {.inline.} =
  ctx.request = request
  ctx.response = response
  ctx.handled = false
  ctx.ctxData = newStringTable(mode = modeCaseSensitive)
  ctx.gScope = gScope
  ctx.size = 0
  ctx.first = true

method extend*(ctx: Context) {.base, gcsafe, inline.} =
  discard

func newContextFrom*(ctx: Context, src: Context) {.deprecated.} =
  ## Creates a new Context by moving object and sharing ref object.
  ctx.request = move src.request
  ctx.response = move src.response
  ctx.session = src.session
  ctx.gScope = src.gScope
  ctx.middlewares = move src.middlewares
  ctx.handled = src.handled
  ctx.size = src.size
  ctx.first = src.first

func newContextTo*(ctx: Context, src: Context) {.deprecated.} =
  ## Creates a new Context by moving object and copying necessary attributes.
  ctx.request = move src.request
  ctx.response = move src.response
  ctx.handled = src.handled

func getSettings*(ctx: Context, key: string): JsonNode {.inline.} =
  ## Get settings from globalSetting.
  ## If key doesn't exist, `nil` will be returned.
  result = ctx.gScope.settings.getOrDefault(key)

proc flash*(ctx: Context, msgs: string, category = FlashLevel.Info) {.inline.} =
  ## Sets flash messages.
  ctx.session.flash(msgs, category)

proc flash*(ctx: Context, msgs: string, category: string) {.inline.} =
  ## Sets flash messages.
  ctx.session.flash(msgs, category)

proc getFlashedMsgs*(ctx: Context): seq[string] {.inline.} =
  ctx.session.messages

proc getFlashedMsgsWithCategory*(ctx: Context): seq[(string, string)] {.inline.} =
  ctx.session.messagesWithCategory

proc getFlashedMsg*(ctx: Context, category: FlashLevel): Option[string] {.inline.} =
  ctx.session.getMessage(category)

proc getFlashedMsg*(ctx: Context, category: string): Option[string] {.inline.} =
  ctx.session.getMessage(category)

proc respond*(
  ctx: Context, code: HttpCode, body: string,
  headers: ResponseHeaders
): Future[void] {.inline.} =
  ## Sends response to the client generating from `code`, `body` and `headers`.
  result = ctx.request.respond(code, body, headers)

proc respond*(ctx: Context): Future[void] {.inline.} =
  ## Sends response to the client generating from `ctx.response`.
  result = ctx.request.respond(ctx.response)

proc respond*(ctx: Context, code: HttpCode, body: string): Future[void] {.inline.} =
  ## Sends response to the client generating from `ctx.response`.
  result = ctx.request.respond(code, body)

proc send*(ctx: Context, content: string): Future[void] {.inline.} =
  ## Sends content to the client.
  result = ctx.request.send(content)

func getCookie*(ctx: Context, key: string, default = ""): string {.inline.} =
  ## Gets the value of `ctx.request.cookies[key]` if key is in cookies. Otherwise, the `default`
  ## value will be returned.
  getCookie(ctx.request, key, default)

proc setCookie*(ctx: Context, cookie: Cookie) =
  ## Sets Cookie for Response.
  ctx.response.setCookie(cookie)

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

proc defaultHandler*(ctx: Context): Future[void] =
  ## Default handler with HttpCode 404.
  ctx.response.code = Http404
  ctx.response.body.setLen(0)
  result = newFuture[void]()
  complete(result)

proc default404Handler*(ctx: Context): Future[void] =
  ## Default 404 pages.
  ctx.response.body = errorPage("404 Not Found!")
  ctx.response.setHeader("content-type", "text/html; charset=UTF-8")
  result = newFuture[void]()
  complete(result)

proc default500Handler*(ctx: Context): Future[void] =
  ## Default 500 pages.
  ctx.response.body = internalServerErrorPage()
  ctx.response.setHeader("content-type", "text/html; charset=UTF-8")
  result = newFuture[void]()
  complete(result)

func getPostParamsOption*(ctx: Context, key: string): Option[string] {.inline.} =
  ## Gets a param from the HttpPost parameters. Returns none(string) if the
  ## request method is not HttpPost or the param is not in the post-parameters.
  ##
  ## `getPostParams` only handles `form-urlencoded` types.
  if ctx.request.reqMethod == HttpPost:
    if ctx.request.postParams.hasKey(key):
      result = some(ctx.request.postParams[key])
    else:
      result = none(string)
  
  else:
    result = none(string)

func getPostParams*(ctx: Context, key: string, default = ""): string {.inline.} =
  ## Gets a param from the HttpPost parameters. Returns the default value 
  ## (which is an empty string if unspecified) if the param is not in the post
  ## parameters.
  ##
  ## `getPostParams` only handles `form-urlencoded` types.
  ##
  let postParamOption: Option[string] = getPostParamsOption(ctx, key)
  if postParamOption.isSome(): 
    result = postParamOption.get() 
  else: 
    result = default

func getQueryParamsOption*(ctx: Context, key: string): Option[string] {.inline.} =
  ## Gets a param from the query strings. Returns none(string) if the param does not exist.
  ## (for example, "www.google.com/hello?name=12", `name=12`).
  let hasQueryParam = ctx.request.queryParams.hasKey(key)
  result = if hasQueryParam: some(decodeUrl(ctx.request.queryParams[key])) else: none(string)

func getQueryParams*(ctx: Context, key: string, default = ""): string {.inline.} =
  ## Gets a param from the query strings(for example, "www.google.com/hello?name=12", `name=12`).
  ## Returns the default value if the param does not exist.
  let queryParamOption: Option[string] = getQueryParamsOption(ctx, key)
  result = if queryParamOption.isSome(): queryParamOption.get() else: default

func getPathParamsOption*(ctx: Context, key: string): Option[string] {.inline.} =
  ## Gets a route parameter(for example, "/hello/{name}"). Returns none(string)
  ## if the param does not exist.
  let hasPathParam = ctx.request.pathParams.hasKey(key)
  result = if hasPathParam: some(decodeUrl(ctx.request.pathParams[key])) else: none(string)

func getPathParams*(ctx: Context, key: string): string {.inline.} =
  ## Gets the route parameters(for example, "/hello/{name}"). Returns an empty 
  ## string if the param does not exist.
  let pathParamOption: Option[string] = getPathParamsOption(ctx, key)
  result = if pathParamOption.isSome(): pathParamOption.get() else: ""

func getPathParams*[T: BaseType](ctx: Context, key: string,
                    default: T): T {.inline.} =
  ## Gets the route parameters(for example, "/hello/{name}"). Returns the
  ## default value if the param does not exist.
  let pathParamOption: Option[string] = getPathParamsOption(ctx, key)
  if pathParamOption.isSome():
    result = pathParamOption.get().parseValue(default) #default serves no purpose here but is kept due to the proc requiring it
  else:
    result = default

func getFormParamsOption*(ctx: Context, key: string): Option[string] {.inline.} =
  ## Gets the contents of the form if key exists.
  ## If you need the filename of the form, use `getUploadFile` instead.
  ## Returns none(string) if the form param does not exist
  ##
  ## `getFormParams` handles both `form-urlencoded` and `multipart/form-data`.
  let hasFormParam = key in ctx.request.formParams.data
  result = if hasFormParam: some(ctx.request.formParams[key].body) else: none(string)

func getFormParams*(ctx: Context, key: string, default = ""): string {.inline.} =
  ## Gets the contents of the form if key exists. Otherwise `default` will be returned.
  ## If you need the filename of the form, use `getUploadFile` instead.
  ## Returns the default value (which is an empty string if unspecified) if the
  ## form param does not exist.
  ##
  ## `getFormParams` handles both `form-urlencoded` and `multipart/form-data`.
  ##
  let formParam: Option[string] = getFormParamsOption(ctx, key)
  result = if formParam.isSome(): formParam.get() else: default

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

func urlFor*(
  ctx: Context, handler: string,
  parameters: openArray[(string, string)] = @[],
  queryParams: openArray[(string, string)] = @[],
  usePlus = true, omitEq = true
): string {.inline.} =
  ## Returns the corresponding name of the handler.
  ## 
  ## **Limitation**:
  ##                Only supports two forms of Route: 
  ##                1. "/route/hello"
  ##                2. "/route/{parameter}/other
  ## 
  if handler in ctx.gScope.reversedRouter:
    result = ctx.gScope.reversedRouter[handler]

  result = multiMatch(result, parameters)
  let queryString = encodeQuery(queryParams, usePlus, omitEq)
  if queryString.len != 0:
    result = multiMatch(result, parameters) & "?" & queryString

func abortExit*(ctx: Context, code = Http401, body = "",
                headers = initResponseHeaders(),
                version = HttpVer11
) {.inline.} =
  ## Aborts the program. It raises `AbortError`.
  ctx.response = abort(code, body, headers, version)
  raise newException(AbortError, "abort exit")

proc attachment*(ctx: Context, downloadName: string, charset = "utf-8") {.inline.} =
  ## `attachment` is used to specify the file which will be downloaded.
  ## 
  ## Params: 
  ##         - ``downloadName``: The name of the file to be downloaded. If the
  ##                             length of the name is zero, the function will return immediately.
  ##         - ``charset``: The Encoding of the file. ``utf-8`` is the default encoding.
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

proc staticFileResponse*(
  ctx: Context, filename, dir: string, mimetype = "",
  downloadName = "", charset = "utf-8", bufSize = 40960,
  headers = none(ResponseHeaders)
) {.async.} =
  ## Returns static files response.
  ## The following middlewares processing will be discarded.
  let
    filePath = dir / filename

  # exists -> have access -> can open
  let filePermission = getFilePermissions(filePath)
  if fpOthersRead notin filePermission:
    if headers.isSome:
      await ctx.respond(code = Http403,
                body = "You do not have permission to access this file.",
                headers = headers.get)
    else:
      await ctx.respond(code = Http403,
                body = "You do not have permission to access this file.")
    ctx.handled = true
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

  if headers.isSome:
    ctx.response.headers = headers.get

  if mimetype.len != 0:
    if charset.len != 0:
      ctx.response.setHeader("Content-Type", fmt"{mimetype}; {charset}")
    else:
      ctx.response.setHeader("Content-Type", mimetype)

  ctx.response.setHeader("Last-Modified", $lastModified)
  ctx.response.setHeader("Etag", etag)

  if downloadName.len != 0:
    ctx.attachment(downloadName)

  var file = openAsync(filePath, fmRead)

  if ctx.request.hasHeader("If-None-Match") and ctx.request.headers[
        "If-None-Match"] == etag:
    await ctx.respond(Http304, "")
  elif contentLength < 10_000_000:
    ctx.response.body = await file.readAll()
    await ctx.respond()
  else:
    ctx.response.setHeader("Content-Length", $contentLength)
    await ctx.respond(Http200, "", ctx.response.headers)

    while true:
      let value = await file.read(bufSize)

      if value.len > 0:
        await ctx.send(value)
      else:
        break

  ctx.handled = true
  file.close()
