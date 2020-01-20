import asynchttpserver, strtabs, uri, asyncdispatch


type
  NativeRequest* = asynchttpserver.Request

  Request* = object
    nativeRequest: NativeRequest
    cookies*: StringTableRef


proc url*(request: Request): Uri =
  request.nativeRequest.url

proc reqMethod*(request: Request): HttpMethod =
  request.nativeRequest.reqMethod

proc respond*(request: Request, status: HttpCode, body: string,
  headers: HttpHeaders = nil): Future[void] =
  request.nativeRequest.respond(status, body, headers)

proc initRequest*(nativeRequest: NativeRequest, cookies = newStringTable()): Request =
  Request(nativeRequest: nativeRequest, cookies: cookies)
