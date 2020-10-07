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

import std/[uri, tables, strutils, strformat, logging, strtabs, options, json, asyncdispatch]
from nativesockets import Port, `$`
from cgi import CgiError

from ./utils import isStaticFile
from ./form import parseFormParams
from ./nativesettings import newSettings, newCtxSettings, 
                             getOrDefault, Settings, LocalSettings,
                             newLocalSettings
import ./httpexception
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
import ./httpcore/httplogue
import ./route
import ./defaultserversettings
import ./request
import ./server

import pkg/cookiejar

export request, server
export httplogue
export strtabs
export tables
export asyncdispatch except register
export options
export json
export basicregex
export configure
export constants
export context except size, incSize, first, `first=`, middlewares, `middlewares=`, addMiddlewares
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
export httpexception
export defaultserversettings


# shutdown events
# TODO I don't like global variables
var dontUseThisShutDownEvents: seq[Event]


proc registerErrorHandler*(app: Prologue, code: HttpCode,
                           handler: ErrorHandler) {.inline.} =
  ## Registers a user-defined error handler. You can specify
  ## `HttpCode` and its corresponding `handler`. 
  ## 
  ## When the HTTP code of response exists in the error handler table,
  ## corresponding handler will be executed.
  app.errorHandlerTable[code] = handler

proc registerErrorHandler*(app: Prologue, code: set[HttpCode],
                           handler: ErrorHandler) {.inline.} =
  ## Registers the same handler with a set of HttpCode.
  for idx in code:
    app.registerErrorHandler(idx, handler)

proc registerErrorHandler*(app: Prologue, code: openArray[HttpCode],
                           handler: ErrorHandler) {.inline.} =
  ## Registers the same handler with a sequence of HttpCode.
  ## This is a helper function.
  runnableExamples:
    ## Examples for all registerErrorHandler
    proc go404*(ctx: Context) {.async.} =
      resp "Something wrong!", Http404

    proc go20x*(ctx: Context) {.async.} =
      resp "Ok!", Http200

    proc go30x*(ctx: Context) {.async.} =
      resp "EveryThing else?", Http301

    let settings = newSettings()
    var app = newApp(settings)
    app.registerErrorHandler(Http404, go404)
    app.registerErrorHandler({Http200 .. Http204}, go20x)
    app.registerErrorHandler(@[Http301, Http304, Http307], go30x)

    doAssert app.errorHandlerTable[Http404] == go404
    doAssert app.errorHandlerTable[Http202] == go20x
    doAssert app.errorHandlerTable[Http304] == go30x

  for idx in code:
    app.registerErrorHandler(idx, handler)

func newSettings*(settings: Settings, localSettings: LocalSettings): Settings =
  ## Creates a new settings.
  ##
  ## Params:
  ##        - `settings` is a global immutable setting for all handlers.
  ##        - `localSettings` is a local immutable setting for corresponding handler or handler group.

  result = newSettings(localSettings.data, settings.address, settings.port, settings.debug, settings.reusePort,
                       settings.staticDirs, settings.appName, settings.bufSize)


proc addRoute*(app: Prologue, route: Regex, handler: HandlerAsync,
               httpMethod = HttpGet, middlewares: seq[HandlerAsync] = @[],
               settings: LocalSettings = nil) {.inline.} =
  ## Adds a single regex `route` with `handler` and don't check whether route is duplicated.
  ## 
  ## Notes: The framework will automatically register `HttpHead` method, if
  ## HttpMethod is `HttpGet`.

  # for group in route.namedGroups.keys:
  #   echo group

  let ctxSettings = 
    if settings == nil:
      nil
    else:
      newSettings(app.gScope.settings, settings)

  if httpMethod == HttpGet:
      app.gScope.reRouter.add (initRePath(route = route, httpMethod = HttpHead), 
                           newPathHandler(handler, middlewares, ctxSettings)
                           )

  app.gScope.reRouter.add (initRePath(route = route, httpMethod = httpMethod), 
                           newPathHandler(handler, middlewares, ctxSettings)
                           )

proc addRoute*(app: Prologue, route: Regex, handler: HandlerAsync,
               httpMethod: seq[HttpMethod], middlewares: seq[HandlerAsync] = @[],
               settings: LocalSettings = nil) {.inline.} =
  ## Adds a single regex `route` and `handler`, but supports a set of HttpMethod.
  for m in httpMethod:
    app.addRoute(route, handler, m, middlewares, settings)

proc addReversedRoute(app: Prologue, name, route: string) {.inline.} =
  ## Adds reversed route.
  ## 
  ## Params:
  ##        - `name` is the user-defined name for `route`.
  if name.len != 0:
    if app.gScope.reversedRouter.hasKey(name):
      raise newException(DuplicatedReversedRouteError,
          fmt"Reversed Route {name} is duplicated!")
    app.gScope.reversedRouter[name] = route.stripRoute

proc addRoute*(app: Prologue, route: string, handler: HandlerAsync,
               httpMethod = HttpGet, name = "", middlewares: seq[HandlerAsync] = @[],
               settings: LocalSettings = nil) {.inline.} =
  ## Adds a single route and handler. It checks whether route is duplicated.
  ## 
  ## Notes: The framework will automatically register `HttpHead` method, if
  ## HttpMethod is `HttpGet`.

  # automatically register HttpHead for HttpGet
  let route = route.stripRoute
  if route.len == 0:
    raise newException(RouteError, "The path of route can't be empty")
  let ctxSettings = 
    if settings == nil:
      nil
    else:
      newSettings(app.gScope.settings, settings)

  if httpMethod == HttpGet:
    app.gScope.router.addRoute(route, HttpHead, handler, middlewares, ctxSettings)

  app.gScope.router.addRoute(route, httpMethod, handler, middlewares, ctxSettings)

  app.addReversedRoute(name, route)

proc addRoute*(app: Prologue, route: string, handler: HandlerAsync,
               httpMethod: seq[HttpMethod], name = "", 
               middlewares: seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  ## Adds a single regex `route` and `handler`, but supports a set of HttpMethod.
  ## It also checks whether route is duplicated
  app.addReversedRoute(name, route)
  for m in httpMethod:
    app.addRoute(route, handler, m, "", middlewares, settings)

proc addRoute*(app: Prologue, patterns: seq[UrlPattern], baseRoute = "", 
               middlewares: Option[seq[HandlerAsync]] = none(seq[HandlerAsync]), 
               settings: LocalSettings = nil) {.inline.} =
  ## Adds multiple routes with handlers.
  if middlewares.isSome:
    let addition = middlewares.get
    for pattern in patterns:
      app.addRoute(baseRoute & pattern.route, pattern.matcher, pattern.httpMethod,
                  pattern.name, addition, settings)
  else:
    for pattern in patterns:
      app.addRoute(baseRoute & pattern.route, pattern.matcher, pattern.httpMethod,
                  pattern.name, pattern.middlewares, settings)

proc head*(app: Prologue, route: string, handler: HandlerAsync, name = "",
           middlewares: seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  ## Adds `route` and `handler` with `HttpHead`.
  app.addRoute(route, handler, HttpHead, name, middlewares, settings)

proc get*(app: Prologue, route: string, handler: HandlerAsync, name = "",
          middlewares: seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  ## Adds `route` and `handler` with `HttpGet` and `HttpHead`.
  app.addRoute(route, handler, HttpGet, name, middlewares, settings)

proc post*(app: Prologue, route: string, handler: HandlerAsync, name = "",
           middlewares: seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  ## Adds `route` and `handler` with `HttpPost`.
  app.addRoute(route, handler, HttpPost, name, middlewares, settings)

proc put*(app: Prologue, route: string, handler: HandlerAsync, name = "",
          middlewares: seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  ## Adds `route` and `handler` with `HttpPut`.
  app.addRoute(route, handler, HttpPut, name, middlewares, settings)

proc delete*(app: Prologue, route: string, handler: HandlerAsync, name = "",
             middlewares: seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  ## Adds `route` and `handler` with `HttpDelete`.
  app.addRoute(route, handler, HttpDelete, name, middlewares, settings)

proc trace*(app: Prologue, route: string, handler: HandlerAsync, name = "",
            middlewares: seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  ## Adds `route` and `handler` with `HttpTrace`.
  app.addRoute(route, handler, HttpTrace, name, middlewares, settings)

proc options*(app: Prologue, route: string, handler: HandlerAsync, name = "",
              middlewares: seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  ## Adds `route` and `handler` with `HttpOptions`.
  app.addRoute(route, handler, HttpOptions, name, middlewares, settings)

proc connect*(app: Prologue, route: string, handler: HandlerAsync, name = "",
              middlewares: seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  ## Adds `route` and `handler` with `HttpConnect`.
  app.addRoute(route, handler, HttpConnect, name, middlewares, settings)

proc patch*(app: Prologue, route: string, handler: HandlerAsync, name = "",
            middlewares: seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  ## Adds `route` and `handler` with `HttpPatch`.
  app.addRoute(route, handler, HttpPatch, name, middlewares, settings)

proc all*(app: Prologue, route: string, handler: HandlerAsync, name = "",
          middlewares: seq[HandlerAsync] = @[], settings: LocalSettings = nil) {.inline.} =
  ## Adds `route` and `handler` with all `HttpMethod`.
  app.addRoute(route, handler, @[HttpGet, HttpPost, HttpPut, HttpDelete,
               HttpTrace, HttpOptions, HttpConnect, HttpPatch], name, middlewares, settings)

func appAddress*(app: Prologue): string {.inline.} =
  ## Gets the address from the settings.
  app.gScope.settings.address

func appDebug*(app: Prologue): bool {.inline.} =
  ## Gets the debug attributes from the settings.
  app.gScope.settings.debug

func appName*(app: Prologue): string {.inline.} =
  ## Gets the appName attributes from the settings.
  app.gScope.settings.appName

func appPort*(app: Prologue): Port {.inline.} =
  ## Gets the port from the settings.
  app.gScope.settings.port

proc execEvent*(event: Event) {.inline.} =
  if event.async:
    waitFor event.asyncHandler()
  else:
    event.syncHandler()

proc shutDownHandler() {.noconv.} =
  # shutdown events

  when defined(windows) and compileOption("threads"):
    # workaround for https://github.com/nim-lang/Nim/issues/4057
    echo "ok"
    setupForeignThreadGC()

  for event in dontUseThisShutDownEvents:
    execEvent(event)

  echo "Shutting down Events are done after having received SIGINT!\n"
  quit(QuitSuccess)

func newApp*(
  settings: Settings, 
  middlewares: seq[HandlerAsync] = @[],
  startup: seq[Event] = @[], 
  shutdown: seq[Event] = @[],
  errorHandlerTable = newErrorHandlerTable({Http404: default404Handler, Http500: default500Handler}),
  appData = newStringTable(mode = modeCaseSensitive)
): Prologue =
  ## Creates a new App instance.
  ## 
  ## Params:
  ##        - `settings` is a global immutable setting which is visible to all handlers.
  ##        - `middlewares` is a global sequence of middlewares.
  ##        - `startup` is used to execute tasks before the application starts.
  ##        - `shutdown` is used to execute tasks after the application stops.
  ##        - `errorHandlerTable` stores HTTP codes and corresponding handlers.
  ##        - `appData` is a global user-defined data.
  if settings == nil:
    raise newException(ValueError, "Settings can't be nil!")
  result = newPrologue(settings = settings, ctxSettings = newCtxSettings(),
                       router = newRouter(), reversedRouter = newReversedRouter(),
                       reRouter = newReRouter(), middlewares = middlewares,
                       startup = startup, shutdown = shutdown,
                       errorHandlerTable = errorHandlerTable, appData = appData)

proc handleNativeRequest(request: var Request) {.inline, gcsafe.} =
  ## Handles the request from the client.

  # process cookie
  if request.hasHeader("cookie"):
    request.cookies.parse(request.headers["cookie", 0])

  let contentType = 
    if request.hasHeader("content-type"):
      request.headers["content-type", 0]
    else:
      ""

  # parse form params
  try:
    request.parseFormParams(contentType)
  except CgiError:
    logging.warn(fmt"Malformed query params: Got ?{request.query}")
  except Exception as e:
    logging.error(&"Malformed form params:\n{e.msg}")

proc handleContext*(app: Prologue, ctx: Context) {.async, gcsafe.} =
  ## Handles the context of each request.
  ## Todo Optimization
  ctx.middlewares = app.middlewares
  logging.debug(fmt"{ctx.request.reqMethod} {ctx.request.url.path}")

  # whether request.path in the static path of settings.
  let staticFileFlag = 
    if ctx.gScope.settings.staticDirs.len != 0:
      isStaticFile(ctx.request.path.decodeUrl, ctx.gScope.settings.staticDirs)
    else:
      (false, "", "")

  try:
    if staticFileFlag.hasValue:
      # serve static files
      await staticFileResponse(ctx, staticFileFlag.filename,
                                staticFileFlag.dir)
    else:
      # serve dynamic contents
      await switch(ctx)
  except RouteError as e:
    ctx.response.code = Http404
    ctx.response.body.setLen(0)
    logging.debug e.msg
  except HttpError as e:
    # catch general http error
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
  if ctx.gScope.settings.debug and ctx.response.code == Http500 and ctx.response.body.len != 0:
    discard
  elif ctx.response.code in app.errorHandlerTable and 
          (ctx.response.body.len == 0 or ctx.response.code == Http500):
    await (app.errorHandlerTable[ctx.response.code])(ctx)

  if not ctx.handled:
    # central processing
    # the context is processed here except static file

    # Only process the context when `ctx.handled` is false.
    await respond(ctx)

    logging.debug($(ctx.response))

proc handleRequest*(app: Prologue, nativeRequest: NativeRequest): Future[void] {.gcsafe.} =
  ## Handles the native request and sends response to the client.
  var request = initRequest(nativeRequest)
  handleNativeRequest(request)
  var
    # initialize response
    ctx = newContext(
      request = request, 
      response = initResponse(HttpVer11, Http200),
                              gScope = app.gScope)
  result = handleContext(app, ctx)

proc run*(app: Prologue) =
  ## Starts an Application.
  
  app.gScope.router.compress()

  # start event
  for event in app.startup:
    execEvent(event)

  dontUseThisShutDownEvents = app.shutdown

  if dontUseThisShutDownEvents.len != 0:
    setControlCHook(shutDownHandler)

  # set the level of logging
  # Notes that you can set `app.appDebug=false` to disable logging printing.
  if logging.getHandlers().len == 0:
    addHandler(newConsoleLogger())
    setLogFilter(if app.appDebug: lvlDebug else: lvlInfo)


  if app.appAddress.len == 0:
    when defined(windows):
      logging.debug(fmt"Prologue is serving at 127.0.0.1:{app.appPort} {app.appName}")
    else:
      logging.debug(fmt"Prologue is serving at 0.0.0.0:{app.appPort} {app.appName}")
  else:
    logging.debug(fmt"Prologue is serving at {app.appAddress}:{app.appPort} {app.appName}")


  app.serve(app.appPort, proc (nativeRequest: NativeRequest): Future[void] {.gcsafe.} =
                           result = handleRequest(app, nativeRequest),
            app.appAddress)


when isMainModule:
  proc hello(ctx: Context) {.async.} =
    logging.debug "hello"
    resp "<h1>Hello, Prologue!</h1>"

  proc home(ctx: Context) {.async.} =
    logging.debug "home"
    resp "<h1>Home</h1>"

  proc helloName(ctx: Context) {.async.} =
    logging.debug "helloname"
    resp "<h1>Hello, " & ctx.getPathParams("name", "Prologue!") & "</h1>"

  proc testRedirect(ctx: Context) {.async.} =
    logging.debug "testRedirect"
    resp redirect("/hello")

  proc login(ctx: Context) {.async.} =
    logging.debug "logging"
    resp loginPage()

  proc doLogin(ctx: Context) {.async.} =
    logging.debug "doLogin"
    resp redirect("/hello/Nim")

  let settings = newSettings(appName = "Prologue", debug = true)
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
