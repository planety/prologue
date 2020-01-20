import asyncdispatch, uri, httpcore
import tables, strutils, strformat, macros, logging, strtabs
import request, response, context, types, middlewares


export Settings
export Prologue
export Context
export httpcore
export strtabs
export asyncdispatch


proc addRoute*(app: Prologue, route: string, handler: Handler, basePath = "",
    httpMethod = HttpGet, middlewares: seq[MiddlewareHandler] = @[]) =
  let path = initPath(route = route, basePath = basePath,
      httpMethod = httpMethod)
  if path in app.router.callable:
    raise newException(DuplicatedRouteError, fmt"Route {route} is duplicated!")
  app.router.callable[path] = newPathHandler(handler, middlewares)

proc addRoute*(app: Prologue, basePath: string, fileName: string) =
  discard

proc abort*(ctx: Context, status = Http401, body = "") {.async.} =
  await ctx.request.respond(status, body)
  logging.debug($status)

proc redirect*(ctx: Context, url: string, status = Http301,
    body = "", delay = 0) {.async.} =

  var headers = newHttpHeaders()
  if delay == 0:
    headers.add("Location", url)
  else:
    headers.add("refresh", fmt"""{delay};url="{url}"""")
  await ctx.request.respond(status, body, headers)
  logging.debug(fmt"{status} {headers}")

proc error404*(ctx: Context, status = Http404,
    body = "<h1>404 Not Found!</h1>") {.async.} =
  await ctx.request.respond(status, body)
  logging.debug($status)

proc defaultHandler*(ctx: Context) {.async.} =
  await error404(ctx)

proc findHandler*(app: Prologue, ctx: Context, path: Path): PathHandler =
  if path in app.router.callable:
    return app.router.callable[path]
  let
    path = path.basePath & path.route
    pathList = path.split("/")

  var flag = true

  for route, handler in app.router.callable.pairs:
    let routeList = (route.basePath & route.route).split("/")
    if pathList.len == routeList.len:
      for idx in 0 ..< pathList.len:
        if pathList[idx] == routeList[idx]:
          continue
        if routeList[idx].startsWith("{"):
          # should be checked in addRoute
          let key = routeList[idx]
          if key.len <= 2:
            raise newException(RouteError, "{} shouldn't be empty!")
          ctx.params[key[1 .. ^2]] = decodeUrl(pathList[idx])
        else:
          flag = false
          break
      if flag:
        return handler
  return newPathHandler(defaultHandler)

proc handle*(ctx: Context) {.async.} =
  await ctx.request.respond(ctx.response.status, ctx.response.body,
      ctx.response.httpHeaders)

proc `$`*(response: Response): string =
  fmt"{response.status} {response.httpHeaders}"

macro resp*(params: typed) =
  var ctx = ident"ctx"
  # let response = ident"response"
  # echo getTypeInst(params).repr
  result = quote do:
    `ctx`.response.body = `params`
    asyncCheck handle(`ctx`)
    logging.debug($(`ctx`.response))

proc initSettings*(port = Port(8080), debug = false, reusePort = true,
    staticDir = "/static", appName = ""): Settings =
  Settings(port: port, debug: debug, reusePort: reusePort, staticDir: staticDir,
      appName: appName)

proc initApp*(settings: Settings, middlewares: seq[MiddlewareHandler] = @[]): Prologue =
  Prologue(server: newPrologueServer(true, settings.reusePort),
      settings: settings, router: newRouter(), middlewares: middlewares)

proc run*(app: Prologue) =
  proc handleRequest(nativeRequest: NativeRequest) {.async.} =
    var request = initRequest(nativeRequest)
    var response = initResponse(HttpVer11, Http200, httpHeaders = {
        "Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders)
    var ctx = newContext(request = request, response = response)

    # gcsafe
    for middlewareHandler in app.middlewares:
      middlewareHandler(ctx)

    logging.debug(fmt"{ctx.request.reqMethod} {ctx.request.url.path}")
    let path = initPath(route = ctx.request.url.path, basePath = "",
    httpMethod = ctx.request.reqMethod)
    # gcsafe
    let pathHandler = app.findHandler(ctx, path)
    for middlewareHandler in pathHandler.middlewares:
      middlewareHandler(ctx)
    await pathHandler.handler(ctx)

  # maybe should read settings from file
  if logging.getHandlers().len == 0:
    addHandler(logging.newConsoleLogger())
    setLogFilter(if app.settings.debug: lvlInfo else: lvlDebug)
  defer: app.close()
  logging.info(fmt"Prologue is serving at 127.0.0.1:{app.settings.port.int} {app.settings.appName}")
  waitFor app.serve(app.settings.port, handleRequest)


when isMainModule:
  proc hello*(ctx: Context) {.async.} =
    resp "<h1>Hello, Prologue!</h1>"

  proc home*(ctx: Context) {.async.} =
    resp "<h1>Home</h1>"

  # proc templ*(ctx: Context) {.async.} =
  #   resp {"name": "string"}.toTable

  proc helloName*(ctx: Context) {.async.} =
    resp "<h1>Hello, " & ctx.params.getOrDefault("name", "Prologue") & "</h1>"

  proc testRedirect*(ctx: Context) {.async.} =
    await redirect(ctx, "/hello")

  let settings = initSettings(appName = "StarLight")
  var app = initApp(settings = settings, @[loggingMiddleware])
  app.addRoute("/", home, "", HttpGet)
  app.addRoute("/", home, "", HttpPost)
  app.addRoute("/home", home, "", HttpGet, @[loggingMiddleware])
  app.addRoute("/hello", hello, "", HttpGet)
  app.addRoute("/redirect", testRedirect, "", HttpGet)
  # app.addRoute("/hello", hello, "advanced"， HttpGet)
  # app.addRoute("/templ", templ, "tempalte", HttpGet)
  app.addRoute("/hello/{name}", helloName, "", HttpGet)
  app.run()
