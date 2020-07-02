import uri, httpcore
import tables, strutils, strformat, logging, strtabs, options, json
from nativesockets import Port, `$`
import cookiejar
from cgi import CgiError


from ./utils import isStaticFile
from ./route import pattern, initPath, initRePath, newPathHandler, newRouter,
    newReRouter, DuplicatedRouteError, DuplicatedReversedRouteError, UrlPattern,
    add, `[]`, `[]=`, hasKey
from ./form import parseFormParams
from ./nativesettings import newSettings, newCtxSettings, 
                             getOrDefault, Settings, LocalSettings,
                             newLocalSettings
from ./httpexception import HttpError, AbortError

import ./dispatch
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
import ./types


import ./request
import ./server
export request, server


export httpcore
export strtabs
export tables
export dispatch except register
export options
export json

export signing
export basicregex
export configure
export constants
export context except size, incSize, first, `first=`
export cookiejar
export encode
export middlewaresbase
export nativesettings
export pages
export response
export route
export types
export urandom
export utils


let
  DefaultErrorHandler = newErrorHandlerTable({Http404: default404Handler, Http500: default500Handler})


proc registerErrorHandler*(app: Prologue, code: HttpCode,
                           handler: ErrorHandler) {.inline.} =
  app.errorHandlerTable[code] = handler

proc registerErrorHandler*(app: Prologue, code: set[HttpCode],
                           handler: ErrorHandler) {.inline.} =
  for idx in code:
    app.registerErrorHandler(idx, handler)

proc registerErrorHandler*(app: Prologue, code: openArray[HttpCode],
                           handler: ErrorHandler) {.inline.} =
  for idx in code:
    app.registerErrorHandler(idx, handler)


proc newSettings*(settings: Settings, localSettings: LocalSettings): Settings {.inline.} =
  result = newSettings(localSettings.data, settings.port, settings.debug, settings.reusePort,
                       settings.staticDirs, settings.appName)
  

proc addRoute*(app: Prologue, route: Regex, handler: HandlerAsync,
               httpMethod = HttpGet, middlewares: seq[HandlerAsync] = @[],
               settings: LocalSettings = nil) {.inline.} =
  ## add single handler route
  ## don't check whether regex routes are duplicated
  # for group in route.namedGroups.keys:
  #   echo group
  if httpMethod == HttpGet:
    app.addRoute(route, handler, HttpHead, middlewares)
  let path = initRePath(route = route, httpMethod = httpMethod)
  app.gScope.reRouter.add (path, newPathHandler(handler, middlewares))

proc addRoute*(app: Prologue, route: Regex, handler: HandlerAsync,
               httpMethod: seq[HttpMethod], middlewares: seq[HandlerAsync] = @[],
               settings: LocalSettings = nil) {.inline.} =
  for m in httpMethod:
    app.addRoute(route, handler, m, middlewares, settings)

proc addReversedRoute(app: Prologue, name, route: string) {.inline.} =
  if name.len != 0:
    if app.gScope.reversedRouter.hasKey(name):
      raise newException(DuplicatedReversedRouteError,
          fmt"Reversed Route {name} is duplicated!")
    app.gScope.reversedRouter[name] = route

proc addRoute*(app: Prologue, route: string, handler: HandlerAsync,
               httpMethod = HttpGet, name = "", middlewares: seq[HandlerAsync] = @[],
               settings: LocalSettings = nil) {.inline.} =
  ## add single handler route
  ## check whether routes are duplicated
  let path = initPath(route = route, httpMethod = httpMethod)
  # automatically register HttpHead for HttpGet
  if httpMethod == HttpGet:
    app.addRoute(route, handler, HttpHead, "", middlewares, settings)

  if app.gScope.router.hasKey(path):
    raise newException(DuplicatedRouteError, fmt"Route {route} is duplicated!")
  if settings == nil:
    app.gScope.router[path] = newPathHandler(handler, middlewares, nil)
  else:
    app.gScope.router[path] = newPathHandler(handler, middlewares, 
                                             newSettings(app.gScope.settings, settings))
  app.addReversedRoute(name, route)

proc addRoute*(app: Prologue, route: string, handler: HandlerAsync,
               httpMethod: seq[HttpMethod], name = "", 
               middlewares: seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  ## add single handler route with multi http method
  ## check whether routes are duplicated
  app.addReversedRoute(name, route)
  for m in httpMethod:
    app.addRoute(route, handler, m, "", middlewares, settings)

proc addRoute*(app: Prologue, patterns: seq[UrlPattern],
               baseRoute = "", settings: LocalSettings = nil) {.inline.} =
  ## add multi handler route
  for pattern in patterns:
    app.addRoute(baseRoute & pattern.route, pattern.matcher, pattern.httpMethod,
                 pattern.name, pattern.middlewares, settings)

proc head*(app: Prologue, route: string, handler: HandlerAsync, name = "",
           middlewares: sink seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  app.addRoute(route, handler, HttpHead, name, middlewares, settings)

proc get*(app: Prologue, route: string, handler: HandlerAsync, name = "",
          middlewares: sink seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  app.addRoute(route, handler, HttpGet, name, middlewares, settings)

proc post*(app: Prologue, route: string, handler: HandlerAsync, name = "",
           middlewares: sink seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  app.addRoute(route, handler, HttpPost, name, middlewares, settings)

proc put*(app: Prologue, route: string, handler: HandlerAsync, name = "",
          middlewares: sink seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  app.addRoute(route, handler, HttpPut, name, middlewares, settings)

proc delete*(app: Prologue, route: string, handler: HandlerAsync, name = "",
             middlewares: sink seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  app.addRoute(route, handler, HttpDelete, name, middlewares, settings)

proc trace*(app: Prologue, route: string, handler: HandlerAsync, name = "",
            middlewares: sink seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  app.addRoute(route, handler, HttpTrace, name, middlewares, settings)

proc options*(app: Prologue, route: string, handler: HandlerAsync, name = "",
              middlewares: sink seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  app.addRoute(route, handler, HttpOptions, name, middlewares, settings)

proc connect*(app: Prologue, route: string, handler: HandlerAsync, name = "",
              middlewares: sink seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  app.addRoute(route, handler, HttpConnect, name, middlewares, settings)

proc patch*(app: Prologue, route: string, handler: HandlerAsync, name = "",
            middlewares: sink seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  app.addRoute(route, handler, HttpPatch, name, middlewares, settings)

proc all*(app: Prologue, route: string, handler: HandlerAsync, name = "",
          middlewares: sink seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  app.addRoute(route, handler, @[HttpGet, HttpPost, HttpPut, HttpDelete,
               HttpTrace, HttpOptions, HttpConnect, HttpPatch], name, middlewares, settings)

proc appDebug*(app: Prologue): bool {.inline.} =
  app.gScope.settings.debug

proc appName*(app: Prologue): string {.inline.} =
  app.gScope.settings.appName

proc appPort*(app: Prologue): Port {.inline.} =
  app.gScope.settings.port

proc newApp*(settings: Settings, middlewares: sink seq[HandlerAsync] = @[],
             startup: sink seq[Event] = @[], shutdown: sink seq[Event] = @[],
             errorHandlerTable = DefaultErrorHandler,
             appData = newStringTable(mode = modeCaseSensitive)): Prologue {.inline.} =
  ## Creates a new App instance.
  if settings == nil:
    raise newException(ValueError, "Settings can't be nil!")
  result = newPrologue(settings = settings, ctxSettings = newCtxSettings(),
                       router = newRouter(), reversedRouter = newReversedRouter(),
                       reRouter = newReRouter(), middlewares = middlewares,
                       startup = startup, shutdown = shutdown,
                       errorHandlerTable = errorHandlerTable, appData = appData)

proc run*(app: Prologue) =
  ## Starts Application.
  for event in app.startup:
    if event.async:
      waitFor event.asyncHandler()
    else:
      event.syncHandler()

  proc handleRequest(nativeRequest: NativeRequest) {.async.} =
    var request = initRequest(nativeRequest = nativeRequest)

    if request.hasHeader("cookie"):
      request.cookies.parse(seq[string](request.headers.getOrDefault("cookie")).join("; "))


    let contentType = if request.hasHeader("content-type"): 
        request.headers["content-type", 0]
      else:
        ""

    try:
      request.parseFormParams(contentType)
    except CgiError:
      logging.warn(fmt"Malformed query params: Got ?{request.query}")
    except Exception as e:
      logging.error(&"Malformed form params:\n{e.msg}")

    var
      response = initResponse(HttpVer11, Http200, headers = {
                             "Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders)
      ctx = newContext(request = request, response = response,
                       gScope = app.gScope)

    ctx.middlewares = app.middlewares
    logging.debug(fmt"{ctx.request.reqMethod} {ctx.request.url.path}")

    let staticFileFlag = if ctx.gScope.settings.staticDirs.len != 0:
        isStaticFile(ctx.request.path, ctx.gScope.settings.staticDirs)
      else:
        (false, "", "")

    try:
      if staticFileFlag.hasValue:
        await staticFileResponse(ctx, staticFileFlag.filename,
                                 staticFileFlag.dir)
      else:
        await switch(ctx)
    except HttpError as e:
      # catch abort error
      logging.debug e.msg
    except AbortError as e:
      # catch abort error
      logging.debug e.msg
    except Exception as e:
      logging.error e.msg
      ctx.response.code = Http500
      ctx.response.body = e.msg
      ctx.response.setHeader("content-type", "text/plain; charset=UTF-8")

    # display error messages only in debug mode
    if ctx.gScope.settings.debug and ctx.response.code == Http500:
      discard
    elif ctx.response.code in app.errorHandlerTable:
      await (app.errorHandlerTable[ctx.response.code])(ctx)

    # central processing
    # all context processed here except static file
    if not ctx.handled:
      await handle(ctx)
    logging.debug($(ctx.response))

  if logging.getHandlers().len == 0:
    addHandler(newConsoleLogger())
    setLogFilter(if app.appDebug: lvlDebug else: lvlInfo)

  when defined(windows):
    logging.debug(fmt"Prologue is serving at 127.0.0.1:{app.appPort} {app.appName}")
  else:
    logging.debug(fmt"Prologue is serving at 0.0.0.0:{app.appPort} {app.appName}")
  app.serve(app.appPort, handleRequest)

  for event in app.shutdown:
    if event.async:
      waitFor event.asyncHandler()
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
