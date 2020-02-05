import httpcore, asyncdispatch, tables, strutils, cgi
import asynchttpserver except Request

import request, route, nativesettings, context, utils, base


type
  Server* = AsyncHttpServer

  Prologue* = object
    server*: Server
    settings*: Settings
    router*: Router
    middlewares*: seq[HandlerAsync]


proc appName*(app: Prologue): string {.inline.} =
  app.settings.appName

proc serve*(app: Prologue, port: Port,
  callback: proc (request: NativeRequest): Future[void] {.closure, gcsafe.},
  address = "") {.async.} =
  await app.server.serve(port, callback, address)

proc close*(app: Prologue) =
  app.server.close()

proc newPrologueServer*(reuseAddr = true, reusePort = false,
                         maxBody = 8388608): Server =
  newAsyncHttpServer(reuseAddr, reusePort, maxBody)

proc findHandler*(ctx: Context): PathHandler =
  let rawPath = initPath(route = ctx.request.url.path,
    httpMethod = ctx.request.reqMethod)
  if rawPath in ctx.router.callable:
    return ctx.router.callable[rawPath]

  let
    path = rawPath.route
    pathList = path.split("/")

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
            pathParams = initPathParams(decodeUrl(pathList[idx]), paramsType)
          ctx.request.pathParams[params] = pathParams
        else:
          flag = false
          break
      if flag:
        return handler
  return newPathHandler(defaultHandler)
