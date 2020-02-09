import httpcore, cgi
import tables, hashes, strutils

import context, utils, base

when not defined(production):
  import naiverequest

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

proc findHandler*(ctx: Context): PathHandler =
  let rawPath = initPath(route = ctx.request.url.path,
    httpMethod = ctx.request.reqMethod)
  if rawPath in ctx.router.callable:
    return ctx.router.callable[rawPath]

  let
    pathList = rawPath.route.split("/")

  for route, handler in ctx.router.callable.pairs:
    let routeList = route.route.split("/")
    var flag = true
    if pathList.len == routeList.len:
      for idx in 0 ..< pathList.len:
        if pathList[idx] == routeList[idx]:
          continue

        if routeList[idx].startsWith("{"):
          # should be checked in addRoute
          let key = routeList[idx]
          if key.len <= 2:
            raise newException(RouteError, "{} shouldn't be empty!")
          let
            (params, paramsType) = parsePathParams(key[1 ..< ^1])

          if not checkPathParams(params, paramsType):
            # not match params types
            flag = false
            break
          let
            pathParams = initPathParams(decodeUrl(pathList[idx]), paramsType)
          ctx.request.pathParams[params] = pathParams
        else:
          flag = false
          break
      if flag:
        return handler
  return newPathHandler(defaultHandler)
