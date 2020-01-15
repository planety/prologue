import asynchttpserver, asyncdispatch, uri, httpcore, httpclient

import tables, strutils, strformat

type
  NativeRequest = asynchttpserver.Request
  PrologueError* = object of Exception
  RouteError* = object of PrologueError
  RouteResetError* = object of PrologueError
  Settings* = object
  Request* = object
    nativeRequest: NativeRequest
    settings: Settings

  Response* = object
    httpVersion*: HttpVersion
    status*: HttpCode
    httpHeaders*: HttpHeaders
    body*: string

  Context* = ref object
    request*: Request
    params*: Table[string, string]
    reponse*: Response

  Handler* = proc(ctx: Context): Future[void]

  Router* = ref object
    callable*: Table[string, Handler]

proc initResponse*(): Response =
  Response(httpVersion: HttpVer11, httpHeaders: newHttpHeaders())

proc abortWith*(response: var Response, status = Http404, body: string) =
  response.status = status
  response.body = body

proc redirectTo*(response: var Response, status = Http301, url: string) =
  response.status = status
  response.httpHeaders.add("Location", url)

proc error*(response: var Response, status = Http404) =
  response.status = Http404
  response.body = "404 Not Found!"

proc newRouter*(): Router =
  Router(callable: initTable[string, Handler]())

proc addRoute*(router: Router, route: string, handler: Handler) =
  router.callable[route] = handler

proc handle*(request: Request, response: Response) {.async.} =
  await request.nativeRequest.respond(response.status, response.body, response.httpHeaders)

# proc hello(): string =
#   return "Hello, Nim......"


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
