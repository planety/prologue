import asyncdispatch, uri, cgi, httpcore, cookies
import tables, strutils, strformat, macros, logging, strtabs
import request, response, context, server, middlewares, pages, route,
    nativesettings, openapi, constants, base, configure


export httpcore
export strtabs
export asyncdispatch
export middlewares
export pages
export request
export response
export context
export server
export pattern
export nativesettings
export configure
export base


proc addRoute*(app: Prologue, route: string, handler: HandlerAsync,
    httpMethod = HttpGet, middlewares: seq[HandlerAsync] = @[]) {.inline.} =
  let path = initPath(route = route, httpMethod = httpMethod)

  if path in app.router.callable:
    raise newException(DuplicatedRouteError, fmt"Route {route} is duplicated!")
  app.router.callable[path] = newPathHandler(handler, middlewares)

proc addRoute*(app: Prologue, patterns: seq[UrlPattern],
    baseRoute = "") =
  for pattern in patterns:
    app.addRoute(baseRoute & pattern.route, pattern.matcher, pattern.httpMethod,
        pattern.middlewares)

proc addRoute*(app: Prologue, urlFile: string, baseRoute = "") =
  discard

macro resp*(params: string) =
  var ctx = ident"ctx"
  # let response = ident"response"

  result = quote do:
    `ctx`.response.body = `params`

macro resp*(params: Response) =
  var ctx = ident"ctx"
  # let response = ident"response"

  result = quote do:
    `ctx`.response = `params`

proc initApp*(settings: Settings, middlewares: seq[HandlerAsync] = @[]): Prologue =
  Prologue(server: newPrologueServer(true, settings.reusePort),
      settings: settings, router: newRouter(), middlewares: middlewares)

proc generateRouterDocs(app: Prologue): string {.used.} =
  discard

proc generateDocs*(app: Prologue) =
  let
    version = OpenApiVersion
    license = initLicense("MIT", "https://www.mit-license.org")
    description = "My Conquest is the Sea of Stars."
    info = initInfo(title = app.settings.appName, description = description,
        licenseName = license.name,
        licenseUrl = license.url, version = PrologueVersion)
    descriptionJson = %* {
      "openapi": version,
      "info": info,
      "paths": {
      "/": {
        "get": {
          "summary": "Root",
          "operationId": "root__get",
          "responses": {
            "200": {
              "description": "Successful Response",
              "content": {
                "application/json": {
                  "schema": {}
                  }
                }
              }
            }
          }
        }
      }
    }
    descriptionDoc = $descriptionJson

  writeDocs(descriptionDoc)

proc run*(app: Prologue) =
  proc handleRequest(nativeRequest: NativeRequest) {.async.} =
    var request = initRequest(nativeRequest = nativeRequest,
        settings = app.settings)
    let
      # /student?name=simon&age=sixteen
      # query -> name=simon&age=sixteen
      urlQuery = request.query # string
      headers = request.headers

    if headers.hasKey("cookies"):
      request.cookies = headers["cookies", 0].parseCookies

    var contentType: string
    if headers.hasKey("content-type"):
      contentType = headers["content-type", 0]

    # get or post forms params
    if "form-urlencoded" in contentType:
      for (key, value) in decodeData(request.body):
        case request.reqMethod
        of HttpGet:
          request.getParams[key] = value
        of HttpPost:
          request.postParams[key] = value
        else:
          discard
    elif "multipart/form-data" in contentType and "boundary" in contentType:
      request.formParams = parseFormPart(request.body, contentType)

    for (key, value) in decodeData(urlQuery):
      request.queryParams[key] = value

    var response = initResponse(HttpVer11, Http200, httpHeaders = {
        "Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders)
    var ctx = newContext(request = request, response = response, router = app.router)

    logging.debug(fmt"{ctx.request.reqMethod} {ctx.request.url.path}")

    # gcsafe
    ctx.middlewares = app.middlewares
    await start(ctx)
    await handle(ctx)
    logging.debug($(ctx.response))


  # maybe should read settings from file
  if logging.getHandlers().len == 0:
    addHandler(logging.newConsoleLogger())
    setLogFilter(if app.settings.debug: lvlDebug else: lvlInfo)
  defer: app.close()

  if app.settings.debug:
    generateDocs(app)

  when defined(windows):
    logging.debug(fmt"Prologue is serving at 127.0.0.1:{app.settings.port.int} {app.settings.appName}")
  else:
    logging.debug(fmt"Prologue is serving at 0.0.0.0:{app.settings.port.int} {app.settings.appName}")
  waitFor app.serve(app.settings.port, handleRequest)


when isMainModule:
  proc hello*(ctx: Context) {.async.} =
    echo "hello"
    resp "<h1>Hello, Prologue!</h1>"

  proc home*(ctx: Context) {.async.} =
    echo "home"
    resp "<h1>Home</h1>"

  proc helloName*(ctx: Context) {.async.} =
    echo "helloname"
    resp "<h1>Hello, " & getPathParams("name", "Prologue!") & "</h1>"

  proc testRedirect*(ctx: Context) {.async.} =
    resp redirect("/hello")

  proc login*(ctx: Context) {.async.} =
    echo ctx.request.path
    resp loginPage()

  proc do_login*(ctx: Context) {.async.} =
    resp redirect("/hello/Nim")

  let settings = newSettings(appName = "StarLight", debug = false)
  var app = initApp(settings = settings, middlewares = @[])
  app.addRoute("/", home, HttpGet)
  app.addRoute("/", home, HttpPost)
  app.addRoute("/home", home, HttpGet, @[debugRequestMiddleware, loggingMiddleware])
  app.addRoute("/hello", hello, HttpGet)
  app.addRoute("/redirect", testRedirect, HttpGet)
  app.addRoute("/login", login, HttpGet)
  app.addRoute("/login", do_login, HttpPost)
  app.addRoute("/hello/{name}", helloName, HttpGet)
  app.run()
