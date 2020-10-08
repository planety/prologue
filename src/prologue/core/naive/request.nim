import std/[asyncnet, uri, strutils, strtabs, asynchttpserver, asyncdispatch]

from ../response import Response
from ../types import FormPart, initFormPart
import ../httpcore/httplogue

import pkg/cookiejar


type
  NativeRequest* = asyncHttpServer.Request
  Request* = object
    nativeRequest*: NativeRequest
    cookies*: CookieJar
    postParams*: StringTableRef
    queryParams*: StringTableRef # Only use queryParams for all url params
    formParams*: FormPart
    pathParams*: StringTableRef


func url*(request: Request): Uri {.inline.} =
  ## Gets the url of the request.
  request.nativeRequest.url

func port*(request: Request): string {.inline.} =
  ## Gets the port of the request.
  request.nativeRequest.url.port

func path*(request: Request): string {.inline.} =
  ## Gets the path of the request.
  request.nativeRequest.url.path

func stripPath*(request: var Request) {.inline.} =
  ## Strips the path of the request.
  request.nativeRequest.url.path = request.nativeRequest.url.path.strip(
                  leading = false, chars = {'/'})

func query*(request: Request): string {.inline.} =
  ## Gets the query strings of the request.
  request.nativeRequest.url.query

func scheme*(request: Request): string {.inline.} =
  ## Gets the scheme of the request.
  request.nativeRequest.url.scheme

func setScheme*(request: var Request, value: string) {.inline.} =
  ## Sets the scheme of the request.
  request.nativeRequest.url.scheme = value

func body*(request: Request): string {.inline.} =
  ## Gets the body of the request. It is only present when
  ## using HttpPost method.
  request.nativeRequest.body

func headers*(request: Request): HttpHeaders {.inline.} =
  ## Gets the `HttpHeaders` of the request.
  request.nativeRequest.headers

func reqMethod*(request: Request): HttpMethod {.inline.} =
  ## Gets the `HttpMethod` of the request.
  request.nativeRequest.reqMethod

func getCookie*(request: Request, key: string, default = ""): string {.inline.} =
  ## Gets the value of `request.cookies[key]` if key is in cookies. Otherwise, the `default`
  ## value will be returned.
  request.cookies.getOrDefault(key, default)

func contentType*(request: Request): string {.inline.} =
  ## Gets the contentType of the request.
  let headers = request.nativeRequest.headers
  if not headers.hasKey("Content-Type"):
    return ""
  result = headers["Content-Type", 0]

func charset*(request: Request): string {.inline.} =
  ## Gets the charset of the request.
  let
    findStr = "charset="
    contentType = request.contentType
  let pos = find(contentType, findStr)
  if pos == -1:
    return ""
  else:
    return contentType[pos + findStr.len .. ^1]

func secure*(request: Request): bool {.inline.} =
  ## Returns True if the request is secure.
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

func hostName*(request: Request): string {.inline.} =
  ## Gets the hostname of the request.
  result = request.nativeRequest.hostname
  let headers = request.nativeRequest.headers
  if headers.hasKey("REMOTE_ADDR"):
    result = headers["REMOTE_ADDR", 0]
  if headers.hasKey("x-forwarded-for"):
    result = headers["x-forwarded-for", 0]

proc send*(request: Request, content: string): Future[void] {.inline.} =
  ## Sends `content` to the client.
  result = request.nativeRequest.client.send(content)

proc respond*(request: Request, code: HttpCode, body: string): Future[void] {.inline.} =
  ## Responds `code`, `body` to the client, the framework
  ## will generate response contents automatically.
  result = request.nativeRequest.respond(code, body, nil)

proc respond*(request: Request, code: HttpCode, body: string,
              headers: ResponseHeaders): Future[void] {.inline.} =
  ## Responds `code`, `body` and `headers` to the client, the framework
  ## will generate response contents automatically.
  let headers = HttpHeaders(table: getTables(headers))
  result = request.nativeRequest.respond(code, body, headers)

proc respond*(request: Request, response: Response): Future[void] {.inline.} =
  ## Responds `response` to the client, the framework
  ## will generate response contents automatically.
  result = request.respond(response.code, response.body,
                           response.headers)

func initRequest*(nativeRequest: NativeRequest, 
                  cookies = initCookieJar(),
                  pathParams = newStringTable(modeCaseSensitive), 
                  queryParams = newStringTable(modeCaseSensitive),
                  postParams = newStringTable(modeCaseSensitive)): Request {.inline.} =
  ## Initializes a new Request.
  Request(nativeRequest: nativeRequest, cookies: cookies,
    pathParams: pathParams, queryParams: queryParams, postParams: postParams)

proc close*(request: Request) =
  ## Closes the request.
  request.nativeRequest.client.close()

func initMockingRequest*(
  httpMethod: HttpMethod,
  headers: HttpHeaders,
  url: Uri,
  cookies = initCookieJar(),
  postParams = newStringTable(),
  queryParams = newStringTable(),
  formParams = initFormPart(),
  pathParams = newStringTable()
): Request =
  ## Initializes a new Request.
  Request(nativeRequest: NativeRequest(headers: headers, reqMethod: httpMethod, url: url),
          cookies: cookies, pathParams: pathParams, queryParams: queryParams,
          postParams: postParams, formParams: formParams)
