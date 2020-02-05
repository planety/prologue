import httpcore
import tables, hashes

import context

type
  PrologueError* = object of Exception
  RouteError* = object of PrologueError
  RouteResetError* = object of RouteError
  DuplicatedRouteError* = object of RouteError


  WebAction* = enum
    Http, Websocket

  UrlPattern* = tuple
    route: string
    matcher: HandlerAsync
    httpMethod: HttpMethod
    webAction: WebAction
    middlewares: seq[HandlerAsync]

  Path* = object
    route*: string
    httpMethod*: HttpMethod

  PathHandler* = ref object
    handler*: HandlerAsync
    middlewares*: seq[HandlerAsync]

  Router* = ref object
    callable*: Table[Path, PathHandler]


proc initPath*(route: string, httpMethod = HttpGet): Path =
  Path(route: route, httpMethod: httpMethod)

proc pattern*(route: string, handler: HandlerAsync, httpMethod = HttpGet,
    webAction: WebAction = Http, middlewares: seq[HandlerAsync] = @[]): UrlPattern =
  (route, handler, httpMethod, webAction, middlewares)

proc hash*(x: Path): Hash =
  var h: Hash = 0
  h = h !& hash(x.route)
  h = h !& hash(x.httpMethod)
  result = !$h

proc newPathHandler*(handler: HandlerAsync, middlewares: seq[HandlerAsync] = @[]): PathHandler =
  PathHandler(handler: handler, middlewares: middlewares)

proc newRouter*(): Router =
  Router(callable: initTable[Path, PathHandler]())
