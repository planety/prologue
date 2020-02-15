import asyncdispatch, uri, cgi, httpcore
import tables, strutils, strformat, macros, logging, strtabs, os

import response, context, pages, route,
    nativesettings, base, configure, utils

import ../middlewares/middlewares, ../openapi/openapi, ../signing/signer
import cookies, types

import regex


when not defined(production):
  import ../ naive / [request, server]
  export request, server

export httpcore
export strtabs
export asyncdispatch
export middlewares
export pages
export response
export context
export pattern
export nativesettings
export configure
export base
export openapi
export regex
export utils
export signer


proc addRoute*(app: Prologue, route: Regex, handler: HandlerAsync,
    httpMethod = HttpGet, middlewares: seq[HandlerAsync] = @[],
        excludeMiddlewares: seq[HandlerAsync] = @[]) {.inline.} =
  ## add single handler route
  ## don't check whether regex routes are duplicated
  let path = initRePath(route = route, httpMethod = httpMethod)
  app.reRouter.callable.add (path, newPathHandler(handler, middlewares,
      excludeMiddlewares))

proc addRoute*(app: Prologue, route: Regex, handler: HandlerAsync,
    httpMethod: seq[HttpMethod], middlewares: seq[HandlerAsync] = @[],
        excludeMiddlewares: seq[HandlerAsync] = @[]) {.inline.} =
  ## add single handler route with multi http method
  ## don't check whether regex routes are duplicated
  for m in httpMethod:
    app.addRoute(route, handler, m, middlewares, excludeMiddlewares)

proc addRoute*(app: Prologue, route: string, handler: HandlerAsync,
    httpMethod = HttpGet, middlewares: seq[HandlerAsync] = @[],
        excludeMiddlewares: seq[HandlerAsync] = @[]) {.inline.} =
  ## add single handler route
  ## check whether routes are duplicated
  let path = initPath(route = route, httpMethod = httpMethod)

  if path in app.router.callable:
    raise newException(DuplicatedRouteError, fmt"Route {route} is duplicated!")
  app.router.callable[path] = newPathHandler(handler, middlewares, excludeMiddlewares)

proc addRoute*(app: Prologue, route: string, handler: HandlerAsync,
    httpMethod: seq[HttpMethod], middlewares: seq[HandlerAsync] = @[],
        excludeMiddlewares: seq[HandlerAsync] = @[]) {.inline.} =
  ## add single handler route with multi http method
  ## check whether routes are duplicated
  for m in httpMethod:
    app.addRoute(route, handler, m, middlewares, excludeMiddlewares)

proc addRoute*(app: Prologue, patterns: seq[UrlPattern],
    baseRoute = "") {.inline.} =
  ## add multi handler route
  for pattern in patterns:
    app.addRoute(baseRoute & pattern.route, pattern.matcher, pattern.httpMethod,
        pattern.middlewares, pattern.excludeMiddlewares)

macro resp*(params: string, status = Http200) =
  ## handy to make ctx's response
  var ctx = ident"ctx"

  result = quote do:
    let response = initResponse(httpVersion = HttpVer11, status = `status`,
      httpHeaders = {"Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders,
          body = `params`)
    `ctx`.response = response

macro resp*(params: Response) =
  ## handy to make ctx's response
  var ctx = ident"ctx"

  result = quote do:
    `ctx`.response = `params`

proc initApp*(settings: Settings, middlewares: seq[HandlerAsync] = @[]): Prologue =
  Prologue(server: newPrologueServer(true, settings.reusePort),
      settings: settings, router: newRouter(), reRouter: newReRouter(),
          middlewares: middlewares)

proc run*(app: Prologue) =
  proc handleRequest(nativeRequest: NativeRequest) {.async.} =
    var request = initRequest(nativeRequest = nativeRequest,
        settings = app.settings)
    let
      # /student?name=simon&age=sixteen
      # query -> name=simon&age=sixteen
      urlQuery = request.query # string
      headers = request.headers

    if headers.hasKey("cookie"):
      request.cookies = seq[string](headers.getOrDefault("cookie")).join("; ").parseCookies

    var contentType: string
    if headers.hasKey("content-type"):
      contentType = headers["content-type", 0]

    # get or post forms params
    if "form-urlencoded" in contentType:
      request.formParams = initFormPart()
      for (key, value) in decodeData(request.body):
        request.formParams[key] = value
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
    var ctx = newContext(request = request, response = response,
        router = app.router, reRouter = app.reRouter)

    ctx.middlewares = app.middlewares
    logging.debug(fmt"{ctx.request.reqMethod} {ctx.request.url.path}")

    let file = splitFile(request.path.strip(chars = {'/'}, trailing = false))

    if file.dir.startsWith(app.settings.staticDir.strip(chars = {'/'},
        trailing = false)):
      await staticFileResponse(ctx, file.name & file.ext, file.dir)
    else:
      await switch(ctx)

    await handle(ctx)
    logging.debug($(ctx.response))


  # TODO maybe should read settings from file
  if logging.getHandlers().len == 0:
    addHandler(logging.newConsoleLogger())
    setLogFilter(if app.settings.debug: lvlDebug else: lvlInfo)
  defer: app.close()


  when defined(windows):
    logging.debug(fmt"Prologue is serving at 127.0.0.1:{app.settings.port.int} {app.settings.appName}")
  else:
    logging.debug(fmt"Prologue is serving at 0.0.0.0:{app.settings.port.int} {app.settings.appName}")
  waitFor app.serve(app.settings.port, handleRequest)


when isMainModule:
  proc hello*(ctx: Context) {.async.} =
    logging.debug "hello"
    resp "<h1>Hello, Prologue!</h1>"

  proc home*(ctx: Context) {.async.} =
    logging.debug "home"
    resp "<h1>Home</h1>"

  proc helloName*(ctx: Context) {.async.} =
    logging.debug "helloname"
    resp "<h1>Hello, " & getPathParams("name", "Prologue!") & "</h1>"

  proc testRedirect*(ctx: Context) {.async.} =
    logging.debug "testRedirect"
    resp redirect("/hello")

  proc login*(ctx: Context) {.async.} =
    logging.debug "logging"
    resp loginPage()

  proc doLogin*(ctx: Context) {.async.} =
    logging.debug "doLogin"
    resp redirect("/hello/Nim")

  let settings = newSettings(appName = "StarLight", debug = true)
  var app = initApp(settings = settings, middlewares = @[stripPathMiddleware()])
  app.addRoute("/", home, HttpGet)
  app.addRoute("/", home, HttpPost)
  app.addRoute("/home", home, HttpGet, @[debugRequestMiddleware()])
  app.addRoute("/hello", hello, HttpGet)
  app.addRoute("/redirect", testRedirect, HttpGet)
  app.addRoute("/login", login, HttpGet)
  app.addRoute("/login", doLogin, HttpPost)
  app.addRoute("/hello/{name}", helloName, HttpGet)
  app.generateDocs()
  app.run()
