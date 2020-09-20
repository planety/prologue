import uri, httpcore
import strutils, strtabs, options

import cookiejar


import asyncdispatch
from ../response import Response
from ../types import FormPart

import httpx except Settings

type
  NativeRequest* = httpx.Request
  Request* = object
    nativeRequest*: NativeRequest
    cookies*: CookieJar
    httpMethod: HttpMethod
    headers: HttpHeaders
    body: string
    url: Uri
    postParams*: StringTableRef
    queryParams*: StringTableRef # Only use queryParams for all url params
    formParams*: FormPart
    pathParams*: StringTableRef

proc createHeaders(headers: HttpHeaders): string =
  result = ""
  if headers != nil:
    for (key, value) in headers.pairs:
      result.add(key & ": " & value & "\c\L")

    result.setLen(result.len - 2) # Strip trailing \c\L

proc url*(request: Request): Uri {.inline.} =
  request.url

proc port*(request: Request): string {.inline.} =
  request.url.port

proc path*(request: Request): string {.inline.} =
  request.url.path

proc stripPath*(request: var Request) {.inline.} =
  request.url.path = request.url.path.strip(
      leading = false, chars = {'/'})

proc query*(request: Request): string {.inline.} =
  request.url.query

proc scheme*(request: Request): string {.inline.} =
  request.url.scheme

proc setScheme*(request: var Request, value: string) {.inline.} =
  request.url.scheme = value

proc body*(request: Request): string {.inline.} =
  request.body

proc headers*(request: Request): HttpHeaders {.inline.} =
  request.headers

proc reqMethod*(request: Request): HttpMethod {.inline.} =
  request.httpMethod

proc getCookie*(request: Request, key: string, default: string): string {.inline.} =
  request.cookies.getOrDefault(key, default)

proc contentType*(request: Request): string {.inline.} =
  if not request.headers.hasKey("Content-Type"):
    return ""
  result = request.headers["Content-Type", 0]

proc charset*(request: Request): string {.inline.} =
  let
    findStr = "charset="
    contentType = request.contentType
    pos = find(contentType, findStr)

  if pos == -1:
    return ""
  else:
    return contentType[pos + findStr.len .. ^1]

proc secure*(request: Request): bool {.inline.} =
  if not request.headers.hasKey("X-Forwarded-Proto"):
    return false

  case request.headers["X-Forwarded-Proto", 0]
  of "http":
    result = false
  of "https":
    result = true
  else:
    result = false

proc hostName*(request: Request): string {.inline.} =
  if request.headers.hasKey("REMOTE_ADDR"):
    result = request.headers["REMOTE_ADDR", 0]
  if request.headers.hasKey("x-forwarded-for"):
    result = request.headers["x-forwarded-for", 0]

proc send*(request: Request, content: string): Future[void] {.inline.} =
  request.nativeRequest.unsafeSend(content)
  var fut = newFuture[void]()
  complete(fut)
  result = fut

proc respond*(request: Request, code: HttpCode, body: string,
              headers: HttpHeaders = newHttpHeaders()): Future[void] {.inline.} =

  let h = headers.createHeaders
  request.nativeRequest.send(code, body, h)
  var fut = newFuture[void]()
  complete(fut)
  result = fut

proc respond*(request: Request, response: Response): Future[void] {.inline.} =
  request.respond(response.code, response.body, response.headers)

proc initRequest*(nativeRequest: NativeRequest, 
                  cookies = initCookieJar(),
                  pathParams = newStringTable(modeCaseSensitive), 
                  queryParams = newStringTable(modeCaseSensitive),
                  postParams = newStringTable(modeCaseSensitive)): Request {.inline.} =

  let url = 
    if nativeRequest.path.isSome:
      parseUri(nativeRequest.path.get)
    else:
      Uri()

  let httpMethod =
    if nativeRequest.httpMethod.isSome:
       nativeRequest.httpMethod.get
    else:
      HttpGet
  
  let body = 
    if nativeRequest.body.isSome:
      nativeRequest.body.get
    else:
      ""

  let headers = 
    if nativeRequest.headers.isSome:
      nativeRequest.headers.get
    else:
      newHttpHeaders()

  Request(nativeRequest: nativeRequest, url: url, httpMethod: httpMethod, body: body,
          headers: headers, cookies: cookies, pathParams: pathParams, queryParams: queryParams,
          postParams: postParams)

proc close*(request: Request) =
  request.nativeRequest.forget()
