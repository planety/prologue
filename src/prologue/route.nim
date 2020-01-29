import asyncdispatch, httpcore
import tables, hashes

import context

type
  PrologueError* = object of Exception
  RouteError* = object of PrologueError
  RouteResetError* = object of RouteError
  DuplicatedRouteError* = object of RouteError

  # change to HandlerAsync later
  HandlerAsync* = proc(ctx: Context): Future[void] {.gcsafe.}
  HandlerSync* = proc(ctx: Context): void {.gcsafe.}
  MiddlewareHandler* = proc(ctx: Context): bool {.nimcall, gcsafe.}

  Matcher* = object
    case async*: bool
    of true:
      handlerAsync*: HandlerAsync
    of false:
      handlerSync*: HandlerSync

  WebAction* = enum
    Http, Websocket

  UrlPattern* = tuple
    route: string
    matcher: Matcher
    httpMethod: HttpMethod
    webAction: WebAction
    middlewares: seq[MiddlewareHandler]

  Path* = object
    route*: string
    httpMethod*: HttpMethod

  PathMatcher* = ref object
    matcher*: Matcher
    middlewares*: seq[MiddlewareHandler]

  Router* = ref object
    callable*: Table[Path, PathMatcher]


proc initPath*(route: string, httpMethod = HttpGet): Path =
  Path(route: route, httpMethod: httpMethod)

proc pattern*(route: string, handler: HandlerSync, httpMethod = HttpGet,
    webAction: WebAction = Http, middlewares: seq[MiddlewareHandler] = @[]): UrlPattern =
  let matcher = Matcher(async: false, handlerSync: handler)
  (route, matcher, httpMethod, webAction, middlewares)

proc pattern*(route: string, handler: HandlerAsync, httpMethod = HttpGet,
    webAction: WebAction = Http, middlewares: seq[MiddlewareHandler] = @[]): UrlPattern =
  let matcher = Matcher(async: true, handlerAsync: handler)
  (route, matcher, httpMethod, webAction, middlewares)

proc hash*(x: Path): Hash =
  var h: Hash = 0
  h = h !& hash(x.route)
  h = h !& hash(x.httpMethod)
  result = !$h

proc newPathMatcher*(handler: HandlerSync, middlewares: seq[MiddlewareHandler] = @[]): PathMatcher =
  let matcher = Matcher(async: false, handlerSync: handler)
  PathMatcher(matcher: matcher, middlewares: middlewares)

proc newPathMatcher*(handler: HandlerAsync, middlewares: seq[MiddlewareHandler] = @[]): PathMatcher =
  let matcher = Matcher(async: true, handlerAsync: handler)
  PathMatcher(matcher: matcher, middlewares: middlewares)

proc newPathMatcher*(matcher: Matcher, middlewares: seq[MiddlewareHandler] = @[]): PathMatcher =
  PathMatcher(matcher: matcher, middlewares: middlewares)

proc newRouter*(): Router =
  Router(callable: initTable[Path, PathMatcher]())
