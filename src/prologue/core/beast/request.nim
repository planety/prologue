import std/[uri, strutils, strtabs, options, asyncdispatch]

from ../response import Response
from ../types import FormPart, initFormPart
import ../httpcore/httplogue

import pkg/cookiejar
import pkg/httpx except Settings


type
  NativeRequest* = httpx.Request
  Request* = object
    nativeRequest*: NativeRequest
    cookies*: CookieJar
    httpMethod: HttpMethod
    headers: HttpHeaders
    url: Uri
    postParams*: StringTableRef
    queryParams*: StringTableRef # Only use queryParams for all url params
    formParams*: FormPart
    pathParams*: StringTableRef


func createHeaders(headers: ResponseHeaders): string {.inline.} =
  if headers.len != 0:
    for (key, value) in headers.pairs:
      result.add(key & ": " & value & "\c\L")

    result.setLen(result.len - 2) # Strip trailing \c\L

func url*(request: Request): Uri {.inline.} =
  ## Gets the url of the request.
  request.url

func port*(request: Request): string {.inline.} =
  ## Gets the port of the request.
  request.url.port

func path*(request: Request): string {.inline.} =
  ## Gets the path of the request.
  request.url.path

func stripPath*(request: var Request) {.inline.} =
  ## Strips the path of the request.
  request.url.path = request.url.path.strip(
                          leading = false, chars = {'/'})

func query*(request: Request): string {.inline.} =
  ## Gets the query strings of the request.
  request.url.query

func scheme*(request: Request): string {.inline.} =
  ## Gets the scheme of the request.
  request.url.scheme

func setScheme*(request: var Request, value: string) {.inline.} =
  ## Sets the scheme of the request.
  request.url.scheme = value

func body*(request: Request): string {.inline.} =
  ## Gets the body of the request. It is only present when
  ## using HttpPost method.
  if request.nativeRequest.body.isSome:
    request.nativeRequest.body.get
  else:
    ""

func headers*(request: Request): HttpHeaders {.inline.} =
  ## Gets the `HttpHeaders` of the request.
  request.headers

func reqMethod*(request: Request): HttpMethod {.inline.} =
  ## Gets the `HttpMethod` of the request.
  request.httpMethod

func getCookie*(request: Request, key: string, default: string): string {.inline.} =
  ## Gets the value of `request.cookies[key]` if key is in cookies. Otherwise, the `default`
  ## value will be returned.
  request.cookies.getOrDefault(key, default)

func contentType*(request: Request): string {.inline.} =
  ## Gets the contentType of the request.
  if not request.headers.hasKey("Content-Type"):
    return ""
  result = request.headers["Content-Type", 0]

func charset*(request: Request): string {.inline.} =
  ## Gets the charset of the request.
  let
    findStr = "charset="
    contentType = request.contentType
    pos = find(contentType, findStr)

  if pos == -1:
    return ""
  else:
    return contentType[pos + findStr.len .. ^1]

func secure*(request: Request): bool {.inline.} =
  ## Returns True if the request is secure.
  if not request.headers.hasKey("X-Forwarded-Proto"):
    return false

  case request.headers["X-Forwarded-Proto", 0]
  of "http":
    result = false
  of "https":
    result = true
  else:
    result = false

func hostName*(request: Request): string {.inline.} =
  ## Gets the hostname of the request.
  if request.headers.hasKey("REMOTE_ADDR"):
    result = request.headers["REMOTE_ADDR", 0]
  if request.headers.hasKey("x-forwarded-for"):
    result = request.headers["x-forwarded-for", 0]

proc send*(request: Request, content: string): Future[void] {.inline.} =
  ## Sends `content` to the client.
  request.nativeRequest.unsafeSend(content)
  result = newFuture[void]()
  complete(result)

proc respond*(request: Request, code: HttpCode, body: string): Future[void] {.inline.} =
  ## Responds `code`, `body` to the client, the framework
  ## will generate the contents of the response automatically.
  request.nativeRequest.send(code, body, "")
  result = newFuture[void]()
  complete(result)

proc respond*(request: Request, code: HttpCode, body: string,
              headers: ResponseHeaders): Future[void] {.inline.} =
  ## Responds `code`, `body` and `headers` to the client, the framework
  ## will generate the contents of the response automatically.
  if headers.hasKey("Content-Length"):
    request.nativeRequest.send(code, body, some(parseInt(headers["Content-Length", 0])), headers.createHeaders)
  else:
    request.nativeRequest.send(code, body, headers.createHeaders)
  result = newFuture[void]()
  complete(result)

proc respond*(request: Request, response: Response): Future[void] {.inline.} =
  ## Responds `response` to the client, the framework
  ## will generate the contents of the response automatically.
  result = request.respond(response.code, response.body, response.headers)

func initRequest*(nativeRequest: NativeRequest, 
                  cookies = initCookieJar(),
                  pathParams = newStringTable(modeCaseSensitive), 
                  queryParams = newStringTable(modeCaseSensitive),
                  postParams = newStringTable(modeCaseSensitive)): Request =
  ## Initializes a new Request.
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

  let headers = 
    if nativeRequest.headers.isSome:
      nativeRequest.headers.get
    else:
      newHttpHeaders()

  Request(nativeRequest: nativeRequest, url: url, httpMethod: httpMethod,
          headers: headers, cookies: cookies, pathParams: pathParams, queryParams: queryParams,
          postParams: postParams)

proc close*(request: Request) =
  ## Closes the request.
  request.nativeRequest.forget()

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
  Request(url: url, httpMethod: httpMethod,
          headers: headers, cookies: cookies, pathParams: pathParams, queryParams: queryParams,
          postParams: postParams, formParams: formParams)
