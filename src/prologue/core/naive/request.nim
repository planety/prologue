import asyncnet, uri
import strutils, strtabs

import asynchttpserver

import cookiejar


import asyncdispatch
from ../response import Response
from ../types import FormPart


type
  NativeRequest* = asyncHttpServer.Request
  Request* = object
    nativeRequest*: NativeRequest
    cookies*: CookieJar
    postParams*: StringTableRef
    queryParams*: StringTableRef # Only use queryParams for all url params
    formParams*: FormPart
    pathParams*: StringTableRef


proc url*(request: Request): Uri {.inline.} =
  ## Gets the url of the request.
  request.nativeRequest.url

proc port*(request: Request): string {.inline.} =
  ## Gets the port of the request.
  request.nativeRequest.url.port

proc path*(request: Request): string {.inline.} =
  ## Gets the path of the request.
  request.nativeRequest.url.path

proc stripPath*(request: var Request) {.inline.} =
  ## Strips the path of the request.
  request.nativeRequest.url.path = request.nativeRequest.url.path.strip(
      leading = false, chars = {'/'})

proc query*(request: Request): string {.inline.} =
  ## Gets the query of the request.
  request.nativeRequest.url.query

proc scheme*(request: Request): string {.inline.} =
  ## Gets the scheme of the request.
  request.nativeRequest.url.scheme

proc setScheme*(request: var Request, value: string) {.inline.} =
  ## Sets the scheme of the request.
  request.nativeRequest.url.scheme = value

proc body*(request: Request): string {.inline.} =
  ## Gets the body of the request.
  request.nativeRequest.body

proc headers*(request: Request): HttpHeaders {.inline.} =
  ## Gets the `HttpHeaders` of the request.
  request.nativeRequest.headers

proc reqMethod*(request: Request): HttpMethod {.inline.} =
  ## Gets the `HttpMethod` of the request.
  request.nativeRequest.reqMethod

proc getCookie*(request: Request, key: string, default: string = ""): string {.inline.} =
  ## Gets the cookie value of the request.
  request.cookies.getOrDefault(key, default)

proc contentType*(request: Request): string {.inline.} =
  ## Gets the contentType of the request.
  let headers = request.nativeRequest.headers
  if not headers.hasKey("Content-Type"):
    return ""
  result = headers["Content-Type", 0]

proc charset*(request: Request): string {.inline.} =
  ## Gets the charset of the request.
  let
    findStr = "charset="
    contentType = request.contentType
  let pos = find(contentType, findStr)
  if pos == -1:
    return ""
  else:
    return contentType[pos + findStr.len .. ^1]

proc secure*(request: Request): bool {.inline.} =
  ## Returns True if request is secure.
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
  ## Gets the hostname of the request.
  result = request.nativeRequest.hostname
  let headers = request.nativeRequest.headers
  if headers.hasKey("REMOTE_ADDR"):
    result = headers["REMOTE_ADDR", 0]
  if headers.hasKey("x-forwarded-for"):
    result = headers["x-forwarded-for", 0]

proc send*(request: Request, content: string): Future[void] {.inline.} =
  result = request.nativeRequest.client.send(content)

proc respond*(request: Request, code: HttpCode, body: string,
              headers: HttpHeaders = newHttpHeaders()): Future[void] {.inline.} =
  result = request.nativeRequest.respond(code, body, headers)

proc respond*(request: Request, response: Response): Future[void] {.inline.} =
  result = request.respond(response.code, response.body,
      response.headers)

proc close*(request: Request) =
  request.nativeRequest.client.close()

proc initRequest*(nativeRequest: NativeRequest, 
                  cookies = initCookieJar(),
                  pathParams = newStringTable(modeCaseSensitive), 
                  queryParams = newStringTable(modeCaseSensitive),
                  postParams = newStringTable(modeCaseSensitive)): Request {.inline.} =
  Request(nativeRequest: nativeRequest, cookies: cookies,
    pathParams: pathParams, queryParams: queryParams, postParams: postParams)
