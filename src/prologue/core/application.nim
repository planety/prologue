import asyncdispatch, uri, httpcore
import tables, strutils, strformat, logging, strtabs, options

import response, context, pages, urandom,
    nativesettings, middlewaresbase

from utils import isStaticFile

from route import pattern, initPath, initRePath, newPathHandler, newRouter,
    newReRouter, DuplicatedRouteError, DuplicatedReveredRouteError, UrlPattern

from form import parseFormParams

import ../middlewares/middlewares, ../openapi/openapi, ../signing/signing
import ../cache/cache, ../configure/configure, ../security/hasher
from ./cookies import parseCookies
from types import SameSite

import regex


when defined(windows) or defined(usestd):
  import ../ naive / [request, server]
  export request, server
else:
  import ../ beast / [request, server]
  export request, server


export httpcore
export strtabs
export tables
export asyncdispatch except register
export middlewares
export pages
export response
export context
export route
export nativesettings
export configure
export openapi
export regex
export utils
export signing
export hasher
export middlewaresbase
export options
export cache
export urandom


proc registerErrorHandler*(app: Prologue, status: HttpCode,
    handler: ErrorHandler) {.inline.} =
  app.errorHandlerTable[status] = handler

proc registerErrorHandler*(app: Prologue, status: set[HttpCode],
    handler: ErrorHandler) {.inline.} =
  for idx in status:
    app.registerErrorHandler(idx, handler)

proc registerErrorHandler*(app: Prologue, status: openArray[HttpCode],
    handler: ErrorHandler) {.inline.} =
  for idx in status:
    app.registerErrorHandler(idx, handler)

proc addRoute*(app: Prologue, route: Regex, handler: HandlerAsync,
    httpMethod = HttpGet, middlewares: sink seq[HandlerAsync] = @[]) {.inline.} =
  ## add single handler route
  ## don't check whether regex routes are duplicated
  # for group in route.namedGroups.keys:
  #   echo group
  if httpMethod == HttpGet:
    app.addRoute(route, handler, HttpHead, middlewares)
  let path = initRePath(route = route, httpMethod = httpMethod)
  app.reRouter.callable.add (path, newPathHandler(handler, middlewares))

proc addRoute*(app: Prologue, route: Regex, handler: HandlerAsync,
    httpMethod: sink seq[HttpMethod], middlewares: sink seq[HandlerAsync] = @[]) {.inline.} =
  for m in httpMethod:
    app.addRoute(route, handler, m, middlewares)

proc addReversedRoute(app: Prologue, name, route: string) {.inline.} =
  if name.len != 0:
    if app.reversedRouter.hasKey(name):
      raise newException(DuplicatedReveredRouteError,
          fmt"Revered Route {name} is duplicated!")
    app.reversedRouter[name] = route

proc addRoute*(app: Prologue, route: string, handler: HandlerAsync,
    httpMethod = HttpGet, name = "", middlewares: sink seq[HandlerAsync] = @[]) {.inline.} =
  ## add single handler route
  ## check whether routes are duplicated
  let path = initPath(route = route, httpMethod = httpMethod)
  # automatically register HttpHead for HttpGet
  # TODO space vs time
  if httpMethod == HttpGet:
    app.addRoute(route, handler, HttpHead, "", middlewares)

  if path in app.router.callable:
    raise newException(DuplicatedRouteError, fmt"Route {route} is duplicated!")
  app.router.callable[path] = newPathHandler(handler, middlewares)
  app.addReversedRoute(name, route)

proc addRoute*(app: Prologue, route: string, handler: HandlerAsync,
    httpMethod: sink seq[HttpMethod], name = "", middlewares: sink seq[
        HandlerAsync] = @[]) {.inline.} =
  ## add single handler route with multi http method
  ## check whether routes are duplicated
  app.addReversedRoute(name, route)
  for m in httpMethod:
    app.addRoute(route, handler, m, "", middlewares)

proc addRoute*(app: Prologue, patterns: sink seq[UrlPattern],
    baseRoute = "") {.inline.} =
  ## add multi handler route
  for pattern in patterns:
    app.addRoute(baseRoute & pattern.route, pattern.matcher, pattern.httpMethod,
        pattern.name, pattern.middlewares)

proc serveStaticFile*(app: Prologue, staticDir: string) {.inline.} =
  app.settings.staticDirs.add(staticDir)

proc serveStaticFile*(app: Prologue, staticDir: sink seq[string]) {.inline.} =
  app.settings.staticDirs.add(staticDir)

proc newApp*(settings: Settings, middlewares: sink seq[HandlerAsync] = @[],
    startup: sink seq[Event] = @[], shutdown: sink seq[Event] = @[],
        errorHandlerTable = {Http404: default404Handler,
            Http500: default500Handler}.newErrorHandlerTable): Prologue =
  when defined(windows) or defined(usestd):
    Prologue(server: newPrologueServer(true, settings.reusePort),
        settings: settings, router: newRouter(), reversedRouter: newReversedRouter(), reRouter: newReRouter(),
                middlewares: middlewares, startup: startup, shutdown: shutdown,
                    errorHandlerTable: errorHandlerTable)
  else:
    Prologue(settings: settings, router: newRouter(), reversedRouter: newReversedRouter(), reRouter: newReRouter(),
            middlewares: middlewares, startup: startup, shutdown: shutdown,
                errorHandlerTable: errorHandlerTable)

proc run*(app: Prologue) =
  for event in app.startup:
    if event.async:
      asyncCheck event.asyncHandler()
    else:
      event.syncHandler()

  proc handleRequest(nativeRequest: NativeRequest) {.async.} =
    var request = initRequest(nativeRequest = nativeRequest,
        settings = app.settings)

    if request.headers.hasKey("cookie"):
      request.cookies = seq[string](request.headers.getOrDefault(
          "cookie")).join("; ").parseCookies

    var contentType: string
    if request.headers.hasKey("content-type"):
      contentType = request.headers["content-type", 0]

    request.parseFormParams(contentType)

    var
      response = initResponse(HttpVer11, Http200, httpHeaders = {
        "Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders)
      ctx = newContext(request = request, response = response,
        router = app.router, reversedRouter = app.reversedRouter,
        reRouter = app.reRouter)

    ctx.middlewares = app.middlewares
    logging.debug(fmt"{ctx.request.reqMethod} {ctx.request.url.path}")

    let staticFileFlag = isStaticFile(ctx.request.path,
        ctx.request.settings.staticDirs)

    try:
      if staticFileFlag.hasValue:
        await staticFileResponse(ctx, staticFileFlag.fileName,
            staticFileFlag.root)
        return
      else:
        await switch(ctx)
    except Exception as e:
      logging.error e.msg
      ctx.response.status = Http500
      ctx.response.body = fmt"{e.msg}"
      ctx.setHeader("content-type", "text/plain; charset=UTF-8")
      # ctx.response.body = fmt"{getStackTrace()}\n{getCurrentExceptionMsg()}"

    if ctx.request.settings.debug and ctx.response.status == Http500:
      discard
    elif ctx.response.status in app.errorHandlerTable:
      # TODO Maybe async and sync
      # TODO Maybe change to Future[void] reduce async
      await (app.errorHandlerTable[ctx.response.status])(ctx)

    # central processing
    # all context processed here except static file
    await handle(ctx)
    logging.debug($(ctx.response))

  # TODO maybe should read settings from file
  if logging.getHandlers().len == 0:
    addHandler(logging.newConsoleLogger())
    setLogFilter(if app.settings.debug: lvlDebug else: lvlInfo)
  # defer: app.close()

  when defined(windows):
    logging.debug(fmt"Prologue is serving at 127.0.0.1:{app.settings.port.int} {app.settings.appName}")
  else:
    logging.debug(fmt"Prologue is serving at 0.0.0.0:{app.settings.port.int} {app.settings.appName}")
  app.serve(app.settings.port, handleRequest)

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
    resp "<h1>Hello, " & ctx.getPathParams("name", "Prologue!") & "</h1>"

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
  app.addRoute("/home", home, HttpGet, middlewares = @[debugRequestMiddleware()])
  app.addRoute("/hello", hello, HttpGet)
  app.addRoute("/redirect", testRedirect, HttpGet)
  app.addRoute("/login", login, HttpGet)
  app.addRoute("/login", doLogin, HttpPost)
  app.addRoute("/hello/{name}", helloName, HttpGet)
  app.serveStaticFile("static")
  app.generateDocs()
  app.run()
