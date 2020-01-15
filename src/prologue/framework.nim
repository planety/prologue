import asynchttpserver, asyncdispatch, uri, httpcore, httpclient, asyncnet


import os, tables, strutils, strformat

type
  PrologueError* = object of Exception
  RouteError* = object of PrologueError
  RouteResetError* = object of PrologueError
  Request* = object
    httpMethod*: HttpMethod
    httpUrl*: Uri
    httpVersion*: HttpVersion
    httpHeaders*: HttpHeaders # HttpHeaders = ref object
                              #   table*: TableRef[string, seq[string]]
    hostName*: string
    body*: string
    cookies*: Table[string, string]

  Response* = object 
    client*: AsyncSocket
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


proc newRouter*(): Router =
  Router(callable: initTable[string, Handler]())

proc addRoute*(router: Router, route: string, handler: Handler) =
  router.callable[route] = handler

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
