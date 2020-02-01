import asynchttpserver, strutils, strtabs, uri, asyncdispatch, tables

import nativesettings, base, response


type
  NativeRequest* = asynchttpserver.Request

  Request* = object
    nativeRequest: NativeRequest
    cookies*: StringTableRef
    postParams*: StringTableRef
    getParams*: StringTableRef
    queryParams*: StringTableRef
    pathParams*: TableRef[string, PathParams]
    settings*: Settings


proc url*(request: Request): Uri {.inline.} =
  request.nativeRequest.url

proc port*(request: Request): string {.inline.} =
  request.nativeRequest.url.port

proc path*(request: Request): string {.inline.} =
  request.nativeRequest.url.path

proc stripPath*(request: var Request) {.inline.} =
  request.nativeRequest.url.path = request.nativeRequest.url.path.strip(
      leading = false, chars = {'/'})

proc query*(request: Request): string {.inline.} =
  request.nativeRequest.url.query

proc scheme*(request: Request): string {.inline.} =
  request.nativeRequest.url.scheme

proc setScheme*(request: var Request, value: string) {.inline.} =
  request.nativeRequest.url.scheme = value

proc body*(request: Request): string {.inline.} =
  request.nativeRequest.body

proc headers*(request: Request): HttpHeaders {.inline.} =
  request.nativeRequest.headers

proc reqMethod*(request: Request): HttpMethod {.inline.} =
  request.nativeRequest.reqMethod

proc getCookie*(request: Request; key: string): string {.inline.} =
  request.cookies.getOrDefault(key, "")

proc secure*(request: Request): bool {.inline.} =
  let headers = request.nativeRequest.headers
  case headers["X-Forwarded-Proto", 0]
  of "http":
    result = false
  of "https":
    result = true
  else:
    result = false

proc hostName*(request: Request): string {.inline.} =
  result = request.nativeRequest.hostname
  let headers = request.nativeRequest.headers
  if headers.hasKey("REMOTE_ADDR"):
    result = headers["REMOTE_ADDR", 0]
  if headers.hasKey("x-forwarded-for"):
    result = headers["x-forwarded-for", 0]

proc respond*(request: Request; status: HttpCode; body: string;
  headers: HttpHeaders = newHttpHeaders()) {.async, inline.} =
  await request.nativeRequest.respond(status, body, headers)

proc respond*(request: Request; response: Response) {.async, inline.} =
  await request.nativeRequest.respond(response.status, response.body,
      response.httpHeaders)

proc initRequest*(nativeRequest: NativeRequest; cookies = newStringTable();
    pathParams = newTable[string, PathParams](); queryParams = newStringTable();
        postParams = newStringTable(); getParams = newStringTable();
            settings = newSettings()): Request {.inline.} =
  Request(nativeRequest: nativeRequest, cookies: cookies,
      pathParams: pathParams, queryParams: queryParams, postParams: postParams,
      getparams: getparams, settings: settings)
