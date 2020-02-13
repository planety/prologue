import asyncdispatch, asynchttpserver, asyncnet, uri
import strutils, strtabs, uri

import ../nativesettings
import ../base
import ../response


type
  NativeRequest* = asynchttpserver.Request

  Request* = object
    nativeRequest: NativeRequest
    cookies*: StringTableRef
    postParams*: StringTableRef
    getParams*: StringTableRef
    queryParams*: StringTableRef
    formParams*: FormPart
    pathParams*: StringTableRef
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

proc getCookie*(request: Request; key: string, default: string): string {.inline.} =
  request.cookies.getOrDefault(key, default)

proc contentType*(request: Request): string {.inline.} =
  let headers = request.nativeRequest.headers
  if not headers.hasKey("Content-Type"):
    return ""
  result = headers["Content-Type", 0]

proc charset*(request: Request): string {.inline.} =
  let
    findStr = "charset="
    contentType = request.contentType
  let pos = find(contentType, findStr)
  if pos == -1:
    return ""
  else:
    return contentType[pos + findStr.len .. ^1]

proc secure*(request: Request): bool {.inline.} =
  let headers = request.nativeRequest.headers
  if not headers.hasKey("X-Forwarded-Proto"):
    return false

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

proc send*(request: Request, content: string) {.inline.} =
  # TODO reduce asyncCheck
  asyncCheck request.nativeRequest.client.send(content)

proc respond*(request: Request; status: HttpCode; body: string;
  headers: HttpHeaders = newHttpHeaders()): Future[void] {.inline.} =
  result = request.nativeRequest.respond(status, body, headers)

proc respond*(request: Request; response: Response): Future[void] {.inline.} =
  result = request.respond(response.status, response.body,
      response.httpHeaders)

proc initRequest*(nativeRequest: NativeRequest; cookies = newStringTable();
    pathParams = newStringTable(); queryParams = newStringTable();
        postParams = newStringTable(); getParams = newStringTable();
            settings = newSettings()): Request {.inline.} =
  Request(nativeRequest: nativeRequest, cookies: cookies,
      pathParams: pathParams, queryParams: queryParams, postParams: postParams,
      getparams: getparams, settings: settings)
