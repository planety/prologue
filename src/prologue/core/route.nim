# Copyright 2020 Zeshen Xing
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


import cgi
import hashes, strutils, strtabs, tables

from ./context import Context, HandlerAsync, Path, RePath, Router, ReRouter,
        PathHandler, defaultHandler, gScope
from ./nativesettings import Settings

from ./basicregex import Regex, RegexMatch, match, groupNames, groupFirstCapture

import ./request
import ./httpcore/httplogue


type
  PrologueError* = object of CatchableError
  RouteError* = object of PrologueError
  RouteResetError* = object of RouteError
  DuplicatedRouteError* = object of RouteError
  DuplicatedReversedRouteError* = object of RouteError

  UrlPattern* = tuple
    route: string
    matcher: HandlerAsync
    httpMethod: seq[HttpMethod]
    name: string
    middlewares: seq[HandlerAsync]


func stripRoute*(route: string): string {.inline.} =
  result = route
  # Don't strip single slash
  if result.len > 1:
    if result[^1] == '/':
      result.setLen(result.high)

func initPath*(route: string, httpMethod = HttpGet): Path =
  Path(route: route, httpMethod: httpMethod)

func initRePath*(route: Regex, httpMethod = HttpGet): RePath =
  RePath(route: route, httpMethod: httpMethod)

func pattern*(route: string, handler: HandlerAsync, httpMethod = HttpGet,
              name = "", middlewares: seq[HandlerAsync] = @[]): UrlPattern =
  (route, handler, @[httpMethod], name, middlewares)

func pattern*(route: string, handler: HandlerAsync, 
              httpMethod: seq[HttpMethod], name = "", 
              middlewares: seq[HandlerAsync] = @[]): UrlPattern =
  (route, handler, httpMethod, name, middlewares)

func hash*(x: Path): Hash =
  var h: Hash = 0
  h = h !& hash(x.route)
  h = h !& hash(x.httpMethod)
  result = !$h

func newPathHandler*(handler: HandlerAsync, middlewares: seq[HandlerAsync] = @[], 
                     settings: Settings = nil): PathHandler {.inline.} =
  PathHandler(handler: handler, middlewares: middlewares, settings: settings)

func newRouter*(): Router {.inline.} =
  Router(callable: initTable[Path, PathHandler]())

func newReRouter*(): ReRouter {.inline.} =
  ReRouter(callable: newSeq[(RePath, PathHandler)]())

proc add*(reRouter: ReRouter, pairs: (RePath, PathHandler)) {.inline.} =
  reRouter.callable.add(pairs)

func `[]`*(router: Router, path: Path): PathHandler {.inline.} =
  router.callable[path]

proc `[]=`*(router: Router, path: Path, pathHandler: PathHandler) {.inline.} =
  router.callable[path] = pathHandler

func hasKey*(router: Router, path: Path): bool {.inline.} =
  router.callable.hasKey(path)

iterator pairs*(router: Router): (Path, PathHandler) {.inline.} =
  for pair in router.callable.pairs:
    yield pair

iterator items*(reRouter: ReRouter): (RePath, PathHandler) {.inline.} =
  for item in reRouter.callable.items:
    yield item

proc findHandler*(ctx: Context): PathHandler =
  ## fixed route -> regex route -> params route
  ## Follow the order of addition.
  
  # Notes path will be striped one slash.
  # Such as 
  # /hello/ -> /hello
  # /hello -> /hello
  # / -> /
  let rawPath = initPath(route = ctx.request.url.path.stripRoute,
                         httpMethod = ctx.request.reqMethod)

  # find fixed route
  if ctx.gScope.router.hasKey(rawPath):
    return ctx.gScope.router[rawPath]

  # find regex route
  for (path, pathHandler) in ctx.gScope.reRouter:
    if path.httpMethod != rawPath.httpMethod:
      continue
    var m: RegexMatch

    if rawPath.route.match(path.route, m):
      for name in m.groupNames():
        ctx.request.pathParams[name] = m.groupFirstCapture(name, rawPath.route)
      return pathHandler

  let
    pathList = rawPath.route.split("/")

  # find params route
  for route, handler in ctx.gScope.router:
    if route.httpMethod != rawPath.httpMethod:
      continue

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
            params = key[1 ..< ^1]

          ctx.request.pathParams[params] = decodeUrl(pathList[idx])
        else:
          flag = false
          break
      if flag:
        return handler
  result = newPathHandler(defaultHandler)
