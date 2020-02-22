import asyncdispatch, uri, cgi, httpcore
import tables, strutils, strformat, logging, strtabs, os, options

import response, context, pages, route,
    nativesettings, corebase, utils, middlewaresbase

import ../middlewares/middlewares, ../openapi/openapi, ../signing/signing
import ../cache/cache, ../configure/configure, ../security/hasher
from ./cookies import parseCookies
from types import SameSite

import regex


when not defined(production):
  import ../ naive / [request, server]
  export request, server

export httpcore
export strtabs
export tables
# export asyncdispatch
export asyncdispatch except register
export middlewares
export pages
export response
export context
export pattern
export nativesettings
export configure
export corebase
export openapi
export regex
export utils
export signing
export hasher
export middlewaresbase
export options
export cache


proc addRoute*(app: Prologue, route: Regex, handler: HandlerAsync,
    httpMethod = HttpGet, middlewares: seq[HandlerAsync] = @[]) {.inline.} =
  ## add single handler route
  ## don't check whether regex routes are duplicated
  # for group in route.namedGroups.keys:
  #   echo group
  let path = initRePath(route = route, httpMethod = httpMethod)
  app.reRouter.callable.add (path, newPathHandler(handler, middlewares))

proc addRoute*(app: Prologue, route: Regex, handler: HandlerAsync,
    httpMethod: seq[HttpMethod], middlewares: seq[HandlerAsync] = @[]) {.inline.} =
  for m in httpMethod:
    app.addRoute(route, handler, m, middlewares)

proc addRoute*(app: Prologue, route: string, handler: HandlerAsync,
    httpMethod = HttpGet, middlewares: seq[HandlerAsync] = @[]) {.inline.} =
  ## add single handler route
  ## check whether routes are duplicated
  let path = initPath(route = route, httpMethod = httpMethod)

  if path in app.router.callable:
    raise newException(DuplicatedRouteError, fmt"Route {route} is duplicated!")
  app.router.callable[path] = newPathHandler(handler, middlewares)
  app.reversedRouter[handler] = route

proc addRoute*(app: Prologue, route: string, handler: HandlerAsync,
    httpMethod: seq[HttpMethod], middlewares: seq[HandlerAsync] = @[]) {.inline.} =
  ## add single handler route with multi http method
  ## check whether routes are duplicated
  for m in httpMethod:
    app.addRoute(route, handler, m, middlewares)

proc addRoute*(app: Prologue, patterns: seq[UrlPattern],
    baseRoute = "") {.inline.} =
  ## add multi handler route
  for pattern in patterns:
    app.addRoute(baseRoute & pattern.route, pattern.matcher, pattern.httpMethod,
        pattern.middlewares)

proc serveStaticFile*(app: Prologue, staticDir: string) {.inline.} =
  app.settings.staticDirs.add(staticDir)

proc serveStaticFile*(app: Prologue, staticDir: seq[string]) {.inline.} =
  app.settings.staticDirs.add(staticDir)

proc newApp*(settings: Settings, middlewares: seq[HandlerAsync] = @[],
    startup: seq[Event] = @[], shutdown: seq[Event] = @[]): Prologue =
  Prologue(server: newPrologueServer(true, settings.reusePort),
      settings: settings, router: newRouter(), reversedRouter: newReversedRouter(), reRouter: newReRouter(),
              middlewares: middlewares, startup: startup, shutdown: shutdown)

proc run*(app: Prologue) =
  for event in app.startup:
    if event.async:
      asyncCheck event.asyncHandler()
    else:
      event.syncHandler()

  proc handleRequest(nativeRequest: NativeRequest) {.async.} =
    var request = initRequest(nativeRequest = nativeRequest,
        settings = app.settings)
    let
      # /student?name=simon&age=sixteen
      # query -> name=simon&age=sixteen
      urlQuery = request.query # string
      headers = request.headers

    if headers.hasKey("cookie"):
      request.cookies = seq[string](headers.getOrDefault("cookie")).join(
          "; ").parseCookies

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
        router = app.router, reversedRouter = app.reversedRouter,
        reRouter = app.reRouter)

    ctx.middlewares = app.middlewares
    logging.debug(fmt"{ctx.request.reqMethod} {ctx.request.url.path}")

    let file = splitFile(request.path.strip(chars = {'/'}, trailing = false))

    var staticFileMatched = false
    for dir in app.settings.staticDirs:
      if file.dir.startsWith(dir.strip(chars = {'/'},
          trailing = false)):
        await staticFileResponse(ctx, file.name & file.ext, file.dir)
        staticFileMatched = true
        break
    if not staticFileMatched:
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
  for event in app.shutdown:
    if event.async:
      asyncCheck event.asyncHandler()
    else:
      event.syncHandler()


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
  var app = newApp(settings = settings, middlewares = @[stripPathMiddleware()])
  app.addRoute("/", home, HttpGet)
  app.addRoute("/", home, HttpPost)
  app.addRoute("/home", home, HttpGet, @[debugRequestMiddleware()])
  app.addRoute("/hello", hello, HttpGet)
  app.addRoute("/redirect", testRedirect, HttpGet)
  app.addRoute("/login", login, HttpGet)
  app.addRoute("/login", doLogin, HttpPost)
  app.addRoute("/hello/{name}", helloName, HttpGet)
  app.serveStaticFile("static")
  app.generateDocs()
  app.run()
