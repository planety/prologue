import asynchttpserver, strtabs, uri, asyncdispatch


type
  NativeRequest* = asynchttpserver.Request

  Request* = object
    nativeRequest: NativeRequest
    cookies*: StringTableRef
    queryParams*: StringTableRef


proc url*(request: Request): Uri =
  request.nativeRequest.url

proc path*(request: Request): string =
  request.nativeRequest.url.path

proc query*(request: Request): string =
  request.nativeRequest.url.query

proc body*(request: Request): string =
  request.nativeRequest.body

proc headers*(request: Request): HttpHeaders =
  request.nativeRequest.headers

proc reqMethod*(request: Request): HttpMethod =
  request.nativeRequest.reqMethod

proc hostName*(request: Request): string =
  result = request.nativeRequest.hostname
  let headers = request.nativeRequest.headers
  if headers.hasKey("REMOTE_ADDR"):
    result = headers["REMOTE_ADDR"]
  if headers.hasKey("x-forwarded-for"):
    result = headers["x-forwarded-for"]

proc respond*(request: Request, status: HttpCode, body: string,
  headers: HttpHeaders = nil): Future[void] =
  request.nativeRequest.respond(status, body, headers)

proc initRequest*(nativeRequest: NativeRequest, cookies = newStringTable(),
    queryParams = newStringTable()): Request =
  Request(nativeRequest: nativeRequest, cookies: cookies,
      queryParams: queryParams)
