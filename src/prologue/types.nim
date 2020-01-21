import httpcore, tables, strtabs, hashes
import asyncdispatch
import asynchttpserver except Request
import request, response, context


type
  PrologueError* = object of Exception
  RouteError* = object of PrologueError
  RouteResetError* = object of RouteError
  DuplicatedRouteError* = object of RouteError

  Handler* = proc(ctx: Context): Future[void] {.gcsafe.}
  MiddlewareHandler* = proc(ctx: Context) {.nimcall, gcsafe.}

  Path* = object
    route*: string
    basePath*: string
    httpMethod*: HttpMethod

  PathHandler* = ref object
    handler*: Handler
    middlewares*: seq[MiddlewareHandler]

  Router* = ref object
    callable*: Table[Path, PathHandler]

  Server* = AsyncHttpServer

  Settings* = object
    port*: Port
    debug*: bool
    reusePort*: bool
    staticDir*: string
    appName*: string

  Prologue* = object
    server*: Server
    settings*: Settings
    router*: Router
    middlewares*: seq[MiddlewareHandler]

proc appName*(app: Prologue): string =
  app.settings.appName

proc initPath*(route: string, basePath = "", httpMethod = HttpGet): Path =
  Path(route: route, basePath: basePath, httpMethod: httpMethod)

proc hash*(x: Path): Hash =
  var h: Hash = 0
  h = h !& hash(x.basePath & x.route)
  h = h !& hash(x.httpMethod)
  result = !$h

proc newContext*(request: Request, response: Response,
    params = newStringTable(), cookies = newStringTable()): Context =
  Context(request: request, response: response, params: params)

proc newPathHandler*(handler: Handler, middlewares: seq[MiddlewareHandler] = @[]): PathHandler =
  PathHandler(handler: handler, middlewares: middlewares) 

proc newRouter*(): Router =
  Router(callable: initTable[Path, PathHandler]())

proc serve*(app: Prologue, port: Port,
  callback: proc (request: NativeRequest): Future[void] {.closure, gcsafe.},
  address = "") {.async.} =
  await app.server.serve(port, callback, address)

proc close*(app: Prologue) =
  app.server.close()

proc newPrologueServer*(reuseAddr = true, reusePort = false,
                         maxBody = 8388608): Server =
  newAsyncHttpServer(reuseAddr, reusePort, maxBody)
