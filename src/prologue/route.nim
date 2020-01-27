import asyncdispatch, httpcore
import tables, hashes

import context

type
  PrologueError* = object of Exception
  RouteError* = object of PrologueError
  RouteResetError* = object of RouteError
  DuplicatedRouteError* = object of RouteError

  Handler* = proc(ctx: Context): Future[void] {.gcsafe.}
  MiddlewareHandler* = proc(ctx: Context): bool {.nimcall, gcsafe.}

  WebAction* = enum
    Http, Websocket

  UrlPattern* = tuple
    route: string
    handler: Handler
    httpMethod: HttpMethod
    webAction: WebAction
    middlewares: seq[MiddlewareHandler]

  Path* = object
    route*: string
    httpMethod*: HttpMethod

  PathHandler* = ref object
    handler*: Handler
    middlewares*: seq[MiddlewareHandler]

  Router* = ref object
    callable*: Table[Path, PathHandler]


proc initPath*(route: string, httpMethod = HttpGet): Path =
  Path(route: route, httpMethod: httpMethod)

proc pattern*(route: string, handler: Handler, httpMethod = HttpGet,
    webAction: WebAction = Http, middlewares: seq[MiddlewareHandler] = @[]): UrlPattern =
  (route, handler, httpMethod, webAction, middlewares)

proc hash*(x: Path): Hash =
  var h: Hash = 0
  h = h !& hash(x.route)
  h = h !& hash(x.httpMethod)
  result = !$h

proc newPathHandler*(handler: Handler, middlewares: seq[MiddlewareHandler] = @[]): PathHandler =
  PathHandler(handler: handler, middlewares: middlewares)

proc newRouter*(): Router =
  Router(callable: initTable[Path, PathHandler]())
