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

import asyncfile, mimetypes, md5, uri, httpcore
import strtabs, tables, strformat, os, times, options, parseutils, json

import asyncdispatch
import ./response, ./pages, ./constants

from ./types import BaseType, Session, `[]`, initSession
from ./configure import parseValue
from ./httpexception import AbortError

from ./basicregex import Regex
from ./nativesettings import Settings, CtxSettings, getOrDefault, hasKey, `[]`

import ./request

import cookiejar


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
    size: int
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

proc default404Handler*(ctx: Context) {.async.}
proc default500Handler*(ctx: Context) {.async.}


func gScope*(ctx: Context): lent GlobalScope {.inline.} =
  ## Gets the gScope attribute of Context.
  ctx.gScope

func size*(ctx: Context): int {.inline.} =
  ctx.size

func incSize*(ctx: Context, num = 1) {.inline.} =
  inc(ctx.size, num)

func first*(ctx: Context): bool {.inline.} =
  ctx.first

proc `first=`*(ctx: Context, first: bool) {.inline.} =
  ctx.first = first

func middlewares*(ctx: Context): lent seq[HandlerAsync] {.inline.} =
  ctx.middlewares

proc `middlewares=`*(ctx: Context, middlewares: seq[HandlerAsync]) {.inline.} =
  ctx.middlewares = middlewares

proc addMiddlewares*(ctx: Context, middleware: HandlerAsync) {.inline.} =
  ctx.middlewares.add(middleware)

proc addMiddlewares*(ctx: Context, middleware: seq[HandlerAsync]) {.inline.} =
  ctx.middlewares.add(middleware)

func initUploadFile*(filename, body: string): UpLoadFile {.inline.} =
  ## Initiates a UploadFile.
  UploadFile(filename: filename, body: body)

func getUploadFile*(ctx: Context, name: string): UpLoadFile {.inline.} =
  ## Gets the UploadFile from request.
  let file = ctx.request.formParams[name]
  initUploadFile(filename = file.params["filename"], body = file.body)

proc save*(uploadFile: UpLoadFile, dir: string, filename = "") {.inline.} =
  ## Saves the UploadFile to ``dir``.
  if not dirExists(dir):
    raise newException(OSError, "Dir doesn't exist.")
  if filename.len == 0:
    writeFile(dir / uploadFile.filename, uploadFile.body)
  else:
    writeFile(dir / filename, uploadFile.body)

proc newErrorHandlerTable*(initialSize = defaultInitialSize): ErrorHandlerTable {.inline.} =
  newTable[HttpCode, ErrorHandler](initialSize)

proc newErrorHandlerTable*(pairs: openArray[(HttpCode,
                           ErrorHandler)]): ErrorHandlerTable {.inline.} =
  newTable[HttpCode, ErrorHandler](pairs)

func newReversedRouter*(): ReversedRouter {.inline.} =
  newStringTable(mode = modeCaseSensitive)

func initEvent*(handler: AsyncEvent): Event {.inline.} =
  Event(async: true, asyncHandler: handler)

func initEvent*(handler: SyncEvent): Event {.inline.} =
  Event(async: false, syncHandler: handler)

func newContext*(request: Request, response: Response,
                 gScope: GlobalScope): Context {.inline.} =
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

proc handle*(ctx: Context): Future[void] {.inline.} =
  result = ctx.request.respond(ctx.response)

proc send*(ctx: Context, content: string): Future[void] {.inline.} =
  result = ctx.request.send(content)

proc respond*(ctx: Context, code: HttpCode, body: string,
  headers: HttpHeaders): Future[void] {.inline.} =
  result = ctx.request.respond(code, body, headers)

func hasHeader*(request: var Request, key: string): bool {.inline.} =
  request.headers.hasKey(key)

proc setHeader*(request: var Request, key, value: string) {.inline.} =
  request.headers[key] = value

proc setHeader*(request: var Request, key: string, value: seq[string]) {.inline.} =
  request.headers[key] = value

proc addHeader*(request: var Request, key, value: string) {.inline.} =
  request.headers.add(key, value)

func getCookie*(ctx: Context, key: string, default: string = ""): string {.inline.} =
  ## Gets Cookie from Request.
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
  ctx.response.code = Http404

proc default404Handler*(ctx: Context) {.async.} =
  ctx.response.body = errorPage("404 Not Found!", PrologueVersion)
  if unlikely(ctx.response.headers != nil):
    ctx.response.headers = newHttpHeaders()
  ctx.response.setHeader("content-type", "text/html; charset=UTF-8")

proc default500Handler*(ctx: Context) {.async.} =
  ctx.response.body = internalServerErrorPage()
  if unlikely(ctx.response.headers != nil):
    ctx.response.headers = newHttpHeaders()
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

proc setResponse*(ctx: Context, code: HttpCode, httpHeaders =
                  {"Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders,
                  body = "", version = HttpVer11) {.inline.} =
  ## Handy to make the response of `ctx`.
  ctx.response.httpVersion = version
  ctx.response.code = code
  ctx.response.headers = httpHeaders
  ctx.response.body = body

proc setResponse*(ctx: Context, response: Response) {.inline.} =
  ## Handy to make the response of `ctx`.
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

func multiMatch*(s: string, replacements: varargs[(string, string)]): string {.inline.} =
  multiMatch(s, replacements.newStringTable)

func urlFor*(ctx: Context, handler: string, parameters: openArray[(string,
             string)] = @[], queryParams: openArray[(string, string)] = @[],
             usePlus = true, omitEq = true): string {.inline.} =

  ## { } can't appear in url
  if handler in ctx.gScope.reversedRouter:
    result = ctx.gScope.reversedRouter[handler]

  result = multiMatch(result, parameters)
  let queryString = encodeQuery(queryParams, usePlus, omitEq)
  if queryString.len != 0:
    result = multiMatch(result, parameters) & "?" & queryString

func abortExit*(ctx: Context, code = Http401, body = "",
                headers = newHttpHeaders(),
                version = HttpVer11) {.inline.} =
  ## Abort the program.
  ctx.response = abort(code, body, headers, version)
  raise newException(AbortError, "abort exit")

proc attachment*(ctx: Context, downloadName = "", charset = "utf-8") {.inline.} =
  ## `attachment` is used to specify the file will be downloaded.
  if downloadName.len == 0:
    return

  if unlikely(ctx.response.headers == nil):
    ctx.response.headers = newHttpHeaders()

  var ext = downloadName.splitFile.ext
  if ext.len > 0:
    ext = ext[1 .. ^1]
    let mimes = ctx.gScope.ctxSettings.mimeDB.getMimetype(ext)
    if mimes.len != 0:
      ctx.response.setHeader("Content-Type", fmt"{mimes}; charset={charset}")

  ctx.response.setHeader("Content-Disposition",
                          &"attachment; filename=\"{downloadName}\"")

proc staticFileResponse*(ctx: Context, filename, dir: string, mimetype = "",
                         downloadName = "", charset = "utf-8", 
                         headers = newHttpHeaders()) {.async.} =  
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
  if unlikely(ctx.response.headers == nil):
    ctx.response.headers = newHttpHeaders()

  if mimetype.len != 0:
    ctx.response.setHeader("Content-Type", fmt"{mimetype}; {charset}")

  ctx.response.setHeader("Last-Modified", $lastModified)
  ctx.response.setHeader("Etag", etag)

  if downloadName.len != 0:
    ctx.attachment(downloadName)

  if contentLength < 20_000_000:
    if ctx.request.hasHeader("If-None-Match") and ctx.request.headers[
        "If-None-Match"] == etag:
      await ctx.respond(Http304, "", nil)
      ctx.handled = true
    else:
      ctx.response.body = readFile(filePath)
  else:
    ctx.response.setHeader("Content-Length", $contentLength)
    await ctx.respond(Http200, "", ctx.response.headers)
    var
      file = openAsync(filePath, fmRead)

    while true:
      let value = await file.read(4096)
      if value.len > 0:
        await ctx.send(value)
      else:
        break

    file.close()
    ctx.handled = true
