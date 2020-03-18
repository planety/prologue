import asyncdispatch, uri, httpcore
import tables, strutils, strformat, logging, strtabs, options, json
from nativeSockets import Port, `$`


from ./utils import isStaticFile
from ./route import pattern, initPath, initRePath, newPathHandler, newRouter,
    newReRouter, DuplicatedRouteError, DuplicatedReveredRouteError, UrlPattern
from ./form import parseFormParams
from ./nativesettings import newSettings, newCtxSettings, getOrDefault, Settings
from ./cookies import parseCookies
from ./types import SameSite

import ./signing/signing
import ./response
import ./context
import ./pages
import ./urandom
import ./middlewaresbase
import ./configure
import ./constants
import ./basicregex
import ./encode


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
export options
export json

export signing
export basicregex
export configure
export constants
export context
export cookies
export encode
export middlewaresbase
export nativesettings
export pages
export response
export route
export types
export urandom
export utils


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
    httpMethod = HttpGet, middlewares: sink seq[HandlerAsync] = @[],
        settings: Settings = nil) {.inline.} =
  ## add single handler route
  ## don't check whether regex routes are duplicated
  # for group in route.namedGroups.keys:
  #   echo group
  if httpMethod == HttpGet:
    app.addRoute(route, handler, HttpHead, middlewares)
  let path = initRePath(route = route, httpMethod = httpMethod)
  app.reRouter.callable.add (path, newPathHandler(handler, middlewares))

proc addRoute*(app: Prologue, route: Regex, handler: HandlerAsync,
    httpMethod: sink seq[HttpMethod], middlewares: sink seq[HandlerAsync] = @[],
    settings: Settings = nil) {.inline.} =
  for m in httpMethod:
    app.addRoute(route, handler, m, middlewares, settings)

proc addReversedRoute(app: Prologue, name, route: string) {.inline.} =
  if name.len != 0:
    if app.reversedRouter.hasKey(name):
      raise newException(DuplicatedReveredRouteError,
          fmt"Revered Route {name} is duplicated!")
    app.reversedRouter[name] = route

proc addRoute*(app: Prologue, route: string, handler: HandlerAsync,
    httpMethod = HttpGet, name = "", middlewares: sink seq[HandlerAsync] = @[],
        settings: Settings = nil) {.inline.} =
  ## add single handler route
  ## check whether routes are duplicated
  let path = initPath(route = route, httpMethod = httpMethod)
  # automatically register HttpHead for HttpGet
  # TODO space vs time
  if httpMethod == HttpGet:
    app.addRoute(route, handler, HttpHead, "", middlewares, settings)

  if path in app.router.callable:
    raise newException(DuplicatedRouteError, fmt"Route {route} is duplicated!")
  app.router.callable[path] = newPathHandler(handler, middlewares, settings)
  app.addReversedRoute(name, route)

proc addRoute*(app: Prologue, route: string, handler: HandlerAsync,
    httpMethod: sink seq[HttpMethod], name = "", middlewares: sink seq[
        HandlerAsync] = @[], settings: Settings = nil) {.inline.} =
  ## add single handler route with multi http method
  ## check whether routes are duplicated
  app.addReversedRoute(name, route)
  for m in httpMethod:
    app.addRoute(route, handler, m, "", middlewares, settings)

proc addRoute*(app: Prologue, patterns: sink seq[UrlPattern],
    baseRoute = "", settings: Settings = nil) {.inline.} =
  ## add multi handler route
  for pattern in patterns:
    app.addRoute(baseRoute & pattern.route, pattern.matcher, pattern.httpMethod,
        pattern.name, pattern.middlewares, settings)

proc head*(app: Prologue, route: string, handler: HandlerAsync, name = "",
    middlewares: sink seq[HandlerAsync] = @[], settings: Settings = nil) {.inline.} =
  app.addRoute(route, handler, HttpHead, name, middlewares, settings)

proc get*(app: Prologue, route: string, handler: HandlerAsync, name = "",
    middlewares: sink seq[HandlerAsync] = @[], settings: Settings = nil) {.inline.} =
  app.addRoute(route, handler, HttpGet, name, middlewares, settings)

proc post*(app: Prologue, route: string, handler: HandlerAsync, name = "",
    middlewares: sink seq[HandlerAsync] = @[], settings: Settings = nil) {.inline.} =
  app.addRoute(route, handler, HttpPost, name, middlewares, settings)

proc put*(app: Prologue, route: string, handler: HandlerAsync, name = "",
    middlewares: sink seq[HandlerAsync] = @[], settings: Settings = nil) {.inline.} =
  app.addRoute(route, handler, HttpPut, name, middlewares, settings)

proc delete*(app: Prologue, route: string, handler: HandlerAsync, name = "",
    middlewares: sink seq[HandlerAsync] = @[], settings: Settings = nil) {.inline.} =
  app.addRoute(route, handler, HttpDelete, name, middlewares, settings)

proc trace*(app: Prologue, route: string, handler: HandlerAsync, name = "",
    middlewares: sink seq[HandlerAsync] = @[], settings: Settings = nil) {.inline.} =
  app.addRoute(route, handler, HttpTrace, name, middlewares, settings)

proc options*(app: Prologue, route: string, handler: HandlerAsync, name = "",
    middlewares: sink seq[HandlerAsync] = @[], settings: Settings = nil) {.inline.} =
  app.addRoute(route, handler, HttpOptions, name, middlewares, settings)

proc connect*(app: Prologue, route: string, handler: HandlerAsync, name = "",
  middlewares: sink seq[HandlerAsync] = @[], settings: Settings = nil) {.inline.} =
  app.addRoute(route, handler, HttpConnect, name, middlewares, settings)

proc patch*(app: Prologue, route: string, handler: HandlerAsync, name = "",
  middlewares: sink seq[HandlerAsync] = @[], settings: Settings = nil) {.inline.} =
  app.addRoute(route, handler, HttpPatch, name, middlewares, settings)

proc all*(app: Prologue, route: string, handler: HandlerAsync, name = "",
  middlewares: sink seq[HandlerAsync] = @[], settings: Settings = nil) {.inline.} =
  app.addRoute(route, handler, @[HttpGet, HttpPost, HttpPut, HttpDelete,
      HttpTrace, HttpOptions, HttpConnect, HttpPatch], name, middlewares, settings)

proc appName*(app: Prologue): string {.inline.} =
  app.settings.getOrDefault("appName").getStr

proc appPort*(app: Prologue): Port {.inline.} =
  app.settings.getOrDefault("port").getInt.Port

proc newApp*(settings: Settings, middlewares: sink seq[HandlerAsync] = @[],
    startup: sink seq[Event] = @[], shutdown: sink seq[Event] = @[],
        errorHandlerTable = {Http404: default404Handler,
            Http500: default500Handler}.newErrorHandlerTable): Prologue {.inline.} =
  if settings == nil:
    raise newException(ValueError, "Settings can't be nil!")
  when defined(windows) or defined(usestd):
    Prologue(server: newPrologueServer(true, settings.getOrDefault(
        "reusePort").getBool), settings: settings, ctxSettings: newCtxSettings(), router: newRouter(), reversedRouter: newReversedRouter(), reRouter: newReRouter(),
                middlewares: middlewares, startup: startup, shutdown: shutdown,
                    errorHandlerTable: errorHandlerTable)
  else:
    Prologue(settings: settings, ctxSettings: newCtxSettings(), router: newRouter(), reversedRouter: newReversedRouter(), reRouter: newReRouter(),
            middlewares: middlewares, startup: startup, shutdown: shutdown,
                errorHandlerTable: errorHandlerTable)


proc run*(app: Prologue) =
  for event in app.startup:
    if event.async:
      asyncCheck event.asyncHandler()
    else:
      event.syncHandler()

  proc handleRequest(nativeRequest: NativeRequest) {.async.} =
    var request = initRequest(nativeRequest = nativeRequest)

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
        reRouter = app.reRouter, settings = app.settings,
        ctxSettings = app.ctxSettings)

    ctx.middlewares = app.middlewares
    logging.debug(fmt"{ctx.request.reqMethod} {ctx.request.url.path}")

    let dirsJson = ctx.settings.getOrDefault("staticDirs")
    var staticFileFlag: tuple[hasValue: bool, fileName, root: string]
    if dirsJson.kind == JArray:
      var
        dirs = newSeq[string](dirsJson.len)
        idx = 0
      for value in dirsJson:
        dirs[idx] = value.getStr
      staticFileFlag = isStaticFile(ctx.request.path, dirs)
    else:
      staticFileFlag = (false, "", "")

    # TODO move to function
    try:
      if staticFileFlag.hasValue:
        await staticFileResponse(ctx, staticFileFlag.fileName,
            staticFileFlag.root)
      else:
        await switch(ctx)
    except Exception as e:
      logging.error e.msg
      ctx.response.status = Http500
      ctx.response.body = e.msg
      ctx.setHeader("content-type", "text/plain; charset=UTF-8")

    if ctx.settings.getOrDefault("debug").getBool and ctx.response.status == Http500:
      discard
    elif ctx.response.status in app.errorHandlerTable:
      # TODO Maybe async and sync
      # TODO Maybe change to Future[void] reduce async
      await (app.errorHandlerTable[ctx.response.status])(ctx)

    # central processing
    # all context processed here except static file
    if not ctx.handled:
      await handle(ctx)
    logging.debug($(ctx.response))

  # TODO maybe should read settings from file
  if logging.getHandlers().len == 0:
    addHandler(logging.newConsoleLogger())
    setLogFilter(if app.settings.getOrDefault(
        "debug").getBool: lvlDebug else: lvlInfo)
  # defer: app.close()

  when defined(windows):
    logging.debug(fmt"Prologue is serving at 127.0.0.1:{app.appPort} {app.appName}")
  else:
    logging.debug(fmt"Prologue is serving at 0.0.0.0:{app.appPort} {app.appName}")
  app.serve(app.appPort, handleRequest)

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
  var app = newApp(settings = settings)
  app.addRoute("/", home, HttpGet)
  app.addRoute("/", home, HttpPost)
  app.addRoute("/home", home, HttpGet)
  app.addRoute("/hello", hello, HttpGet)
  app.addRoute("/redirect", testRedirect, HttpGet)
  app.addRoute("/login", login, HttpGet)
  app.addRoute("/login", doLogin, HttpPost)
  app.addRoute("/hello/{name}", helloName, HttpGet)
  # app.serveStaticFile("static")
  # app.serveDocs()
  app.run()
