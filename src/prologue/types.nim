import httpcore, tables, strtabs, hashes
import asyncdispatch
import asynchttpserver except Request
import request, response


type
  PrologueError* = object of Exception
  RouteError* = object of PrologueError
  RouteResetError* = object of RouteError
  DuplicatedRouteError* = object of RouteError

  Context* = ref object
    request*: Request
    response*: Response
    params*: StringTableRef

  Handler* = proc(ctx: Context): Future[void]

  Path* = object
    route*: string
    basePath*: string
    httpMethod*: HttpMethod

  Router* = ref object
    callable*: Table[Path, Handler]

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

proc newRouter*(): Router =
  Router(callable: initTable[Path, Handler]())

proc serve*(app: Prologue, port: Port,
  callback: proc (request: NativeRequest): Future[void] {.closure, gcsafe.},
  address = "") {.async.} =
  await app.server.serve(port, callback, address)

proc close*(app: Prologue) =
  app.server.close()

proc newPrologueServer*(reuseAddr = true, reusePort = false,
                         maxBody = 8388608): Server =
  newAsyncHttpServer(reuseAddr, reusePort, maxBody)
