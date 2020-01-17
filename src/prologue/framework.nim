import asynchttpserver, asyncdispatch, uri, httpcore, httpclient

import tables, strutils, strformat, macros

type
  NativeRequest = asynchttpserver.Request
  PrologueError* = object of Exception
  RouteError* = object of PrologueError
  RouteResetError* = object of PrologueError
  Settings* = object
    debug: bool
    address: string
    port: Port
  Request* = ref object
    nativeRequest: NativeRequest
    params*: Table[string, string]
    settings: Settings

  Response* = ref object
    httpVersion*: HttpVersion
    status*: HttpCode
    httpHeaders*: HttpHeaders
    body*: string

  Handler* = proc(request: Request): Future[void]

  Router* = ref object
    callable*: Table[string, Handler]
    httpMethod*: HttpMethod

  Prologue* = object
    setting: Settings
    router: Router


proc initResponse*(): Response =
  Response(httpVersion: HttpVer11, httpHeaders: newHttpHeaders())

proc abortWith*(response: var Response, status = Http404, body = "") =
  response.status = status
  response.body = body

proc redirectTo*(response: var Response, status = Http301, url: string, body = "", delay = 0) =
  response.status = status
  if delay == 0:
    response.httpHeaders.add("Location", url)
  else:
    response.httpHeaders.add("refresh", fmt"""{delay};url="{url}"""")

proc error*(response: var Response, status = Http404, body = "404 Not Found!") =
  response.status = Http404
  response.body = body

proc newRouter*(): Router =
  Router(callable: initTable[string, Handler]())

proc addRoute*(router: Router, route: string, handler: Handler, httpMethod = HttpGet) =
  router.callable[route] = handler
  router.httpMethod = httpMethod

proc handle*(request: Request, response: Response) {.async.} =
  await request.nativeRequest.respond(response.status, response.body, response.httpHeaders)

macro resp*(params: untyped) =
  let request = ident"request"
  let response = ident"response"
  result = quote do:
    handle(request, response)

proc run*(port: Port, server: AsyncHttpServer) =
  proc handleRequest(nativeRequest: NativeRequest) {.async.} =
    # await handle(nativeRequest, response)
    discard

  waitFor server.serve(port, handleRequest)
# proc hello(request: Request) =
#   resp "<h1>Hello, Nim</h1>"




# macro callHandler(s: string): untyped =
#   result = newIdentNode(strVal(s))

# var server = newAsyncHttpServer()
# proc cb(req: Request) {.async, gcsafe.} =
#   var router = newRouter()
#   router.addRoute("/hello", "hello")
#   router.addRoute("/hello/<name>", "hello")
#   if req.url.path in router.callable:
#     let call = router.callable[req.url.path]
#     let response = callHandler(call)
#     echo response
#     # await req.respond(Http200, call)

#   await req.respond(Http200, "It's ok")



# waitFor server.serve(Port(5000), cb)
