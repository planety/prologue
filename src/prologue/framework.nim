import asyncdispatch, uri, cgi, httpcore, cookies
import tables, strutils, strformat, macros, logging, strtabs
import request, response, context, types, middlewares, pages


export Settings
export Prologue
export httpcore
export strtabs
export asyncdispatch
export middlewares
export pages
export request
export response
export context

const PrologueVersion = "0.1.0"


proc addRoute*(app: Prologue, route: string, handler: Handler,
    httpMethod = HttpGet, middlewares: seq[MiddlewareHandler] = @[]) =
  let path = initPath(route = route,
      httpMethod = httpMethod)
  if path in app.router.callable:
    raise newException(DuplicatedRouteError, fmt"Route {route} is duplicated!")
  app.router.callable[path] = newPathHandler(handler, middlewares)

proc addRoute*(app: Prologue, route: seq[(string, Handler, HttpMethod)],
    baseRoute = "") =
  discard

proc addRoute*(app: Prologue, urlFile: string, baseRoute = "") =
  discard

proc abort*(status = Http401, body = ""): Response =
  result = initResponse(HttpVer11, status = status, body = body)

proc redirect*(url: string, status = Http301,
    body = "", delay = 0): Response =

  var headers = newHttpHeaders()
  if delay == 0:
    headers.add("Location", url)
  else:
    headers.add("refresh", fmt"""{delay};url="{url}"""")
  result = initResponse(HttpVer11, status = status, httpHeaders = headers, body = body)


proc error404*(status = Http404,
    body = "<h1>404 Not Found!</h1>"): Response =
  result = initResponse(HttpVer11, status = status, body = body)

proc defaultHandler*(ctx: Context) {.async.} =
  let response = error404(body = errorPage("404 Not Found!", PrologueVersion))
  await ctx.request.respond(response)

proc findHandler*(app: Prologue, ctx: Context, path: Path): PathHandler =
  if path in app.router.callable:
    return app.router.callable[path]
  let
    path = path.route
    pathList = path.split("/")


  for route, handler in app.router.callable.pairs:
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
          ctx.params[key[1 .. ^2]] = decodeUrl(pathList[idx])
        else:
          flag = false
          break
      if flag:
        return handler
  return newPathHandler(defaultHandler)

proc handle*(ctx: Context) {.async.} =
  await ctx.request.respond(ctx.response)

proc `$`*(response: Response): string =
  fmt"{response.status} {response.httpHeaders}"

macro resp*(params: string) =
  var ctx = ident"ctx"
  # let response = ident"response"

  result = quote do:
    `ctx`.response.body = `params`
    asyncCheck handle(`ctx`)
    logging.debug($(`ctx`.response))

macro resp*(params: Response) =
  var ctx = ident"ctx"
  # let response = ident"response"

  result = quote do:
    `ctx`.response = `params`
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
    var request = initRequest(nativeRequest = nativeRequest,
        queryParams = newStringTable())
    let
      urlQuery = request.query
      headers = request.headers

    if headers.hasKey("cookies"):
      request.cookies = headers["cookies"].parseCookies

    for (key, value) in decodeData(urlQuery):
      request.queryParams[key] = value

    var response = initResponse(HttpVer11, Http200, httpHeaders = {
        "Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders)
    var ctx = newContext(request = request, response = response)

    # gcsafe
    for middlewareHandler in app.middlewares:
      middlewareHandler(ctx)

    logging.debug(fmt"{ctx.request.reqMethod} {ctx.request.url.path}")
    let path = initPath(route = ctx.request.url.path,
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
  when defined(windows):
    logging.info(fmt"Prologue is serving at 127.0.0.1:{app.settings.port.int} {app.settings.appName}")
  else:
    logging.info(fmt"Prologue is serving at 0.0.0.0:{app.settings.port.int} {app.settings.appName}")
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
    resp redirect("/hello")

  proc login*(ctx: Context) {.async.} =
    resp loginPage()

  proc do_login*(ctx: Context) {.async.} =
    resp redirect("/hello/Nim")

  let settings = initSettings(appName = "StarLight")
  var app = initApp(settings = settings, middlewares = @[debugRequestMiddleware])
  app.addRoute("/", home, HttpGet)
  app.addRoute("/", home, HttpPost)
  app.addRoute("/home", home, HttpGet)
  app.addRoute("/hello", hello, HttpGet)
  app.addRoute("/redirect", testRedirect, HttpGet)
  app.addRoute("/login", login, HttpGet)
  app.addRoute("/login", do_login, HttpPost, @[debugRequestMiddleware])
  # app.addRoute("/hello", hello, HttpGet)
  # app.addRoute("/templ", templ, HttpGet)
  app.addRoute("/hello/{name}", helloName, HttpGet)
  app.run()
