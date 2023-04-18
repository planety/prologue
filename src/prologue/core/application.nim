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

import std/[os, uri, tables, strutils, strformat, logging, strtabs, options, json, asyncdispatch]
from std/nativesockets import Port, `$`

from ./form import parseFormParams
from ./nativesettings import newSettings, newCtxSettings,
                             getOrDefault, Settings, loadSettings
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
import ./request
import ./server
import ./group

import pkg/cookiejar

export group
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
export httpexception


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

    var app = newApp()
    app.registerErrorHandler(Http404, go404)
    app.registerErrorHandler({Http200 .. Http204}, go20x)
    app.registerErrorHandler(@[Http301, Http304, Http307], go30x)

    doAssert app.errorHandlerTable[Http404] == go404
    doAssert app.errorHandlerTable[Http202] == go20x
    doAssert app.errorHandlerTable[Http304] == go30x

  for idx in code:
    app.registerErrorHandler(idx, handler)

# -------------------------------- Regex Route --------------------------------

proc addRoute*(app: Prologue, route: Regex, handler: HandlerAsync,
               httpMethod = HttpGet, middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds a single regex `route` with `handler` and don't check whether route is duplicated.
  ## 
  ## Notes: The framework will automatically register `HttpHead` method, if
  ## HttpMethod is `HttpGet`.

  if httpMethod == HttpGet:
      app.gScope.reRouter.add (initRePath(route = route, httpMethod = HttpHead), 
                           newPathHandler(handler, @middlewares)
                           )

  app.gScope.reRouter.add (initRePath(route = route, httpMethod = httpMethod), 
                           newPathHandler(handler, @middlewares)
                           )

proc addRoute*(app: Prologue, route: Regex, handler: HandlerAsync,
               httpMethod: openArray[HttpMethod], 
               middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds a single regex `route` and `handler`, but supports a set of HttpMethod.
  for m in httpMethod:
    app.addRoute(route, handler, m, middlewares)

# -------------------------------- Parameters Route --------------------------------

func scanRoute(route: string): bool {.inline.} =
  for c in route:
    case c:
    of '$', '*':
      return true
    else:
      discard 

proc addReversedRoute(app: Prologue, name, route: string) =
  ## Adds reversed route.
  ## 
  ## Params:
  ##        - `name` is a user-defined name for `route`.
  if name.len != 0:
    if app.gScope.reversedRouter.hasKey(name):
      let origin = app.gScope.reversedRouter[name]
      if origin == route:
        raise newException(RouteError, 
            fmt"Reversed Route name(`{name}`) is already set for the same route(`{route}`)!")
      else:
        raise newException(DuplicatedReversedRouteError,
            fmt"Reversed Route name(`{name}`) is already set for the different route(`{origin}`)!")

    if scanRoute(route):
      raise newException(RouteError, fmt"Route {route} contains $ or *")

    app.gScope.reversedRouter[name] = route

proc addRoute*(app: Prologue, route: string, handler: HandlerAsync,
               httpMethod = HttpGet, name = "", 
               middlewares: openArray[HandlerAsync] = @[]) =
  ## Adds a single route and handler. It checks whether route is duplicated.
  ## 
  ## Notes: The framework will automatically register `HttpHead` method, if
  ## HttpMethod is `HttpGet`.

  # automatically register HttpHead for HttpGet
  let route = route.stripRoute
  if route.len == 0:
    raise newException(RouteError, "The path of route can't be empty")

  if httpMethod == HttpGet:
    app.gScope.router.addRoute(route, HttpHead, handler, @middlewares)

  app.gScope.router.addRoute(route, httpMethod, handler, @middlewares)

  app.addReversedRoute(name, route)

proc addRoute*(app: Prologue, route: string, handler: HandlerAsync,
               httpMethod: openArray[HttpMethod], name = "", 
               middlewares: openArray[HandlerAsync] = @[]) =
  ## Adds a single `route` and `handler`, but supports a set of HttpMethod.
  ## It also checks whether route is duplicated
  for m in httpMethod:
    app.addRoute(route, handler, m, "", middlewares)
  app.addReversedRoute(name, route.stripRoute)

proc addRoute*(app: Prologue, patterns: openArray[UrlPattern], baseRoute = "", 
               middlewares: Option[seq[HandlerAsync]] = none(seq[HandlerAsync])) =
  ## Adds multiple routes with handlers.
  if middlewares.isSome:
    let additional = middlewares.get
    for pattern in patterns:
      app.addRoute(baseRoute & pattern.route, pattern.matcher, pattern.httpMethod,
                  pattern.name, additional)
  else:
    for pattern in patterns:
      app.addRoute(baseRoute & pattern.route, pattern.matcher, pattern.httpMethod,
                  pattern.name, pattern.middlewares)

# -------------------------------- API Route --------------------------------

proc head*(app: Prologue, route: string, handler: HandlerAsync, name = "",
           middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with `HttpHead`.
  app.addRoute(route, handler, HttpHead, name, middlewares)

proc get*(app: Prologue, route: string, handler: HandlerAsync, name = "",
          middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with `HttpGet` and `HttpHead`.
  app.addRoute(route, handler, HttpGet, name, middlewares)

proc post*(app: Prologue, route: string, handler: HandlerAsync, name = "",
           middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with `HttpPost`.
  app.addRoute(route, handler, HttpPost, name, middlewares)

proc put*(app: Prologue, route: string, handler: HandlerAsync, name = "",
          middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with `HttpPut`.
  app.addRoute(route, handler, HttpPut, name, middlewares)

proc delete*(app: Prologue, route: string, handler: HandlerAsync, name = "",
             middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with `HttpDelete`.
  app.addRoute(route, handler, HttpDelete, name, middlewares)

proc trace*(app: Prologue, route: string, handler: HandlerAsync, name = "",
            middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with `HttpTrace`.
  app.addRoute(route, handler, HttpTrace, name, middlewares)

proc options*(app: Prologue, route: string, handler: HandlerAsync, name = "",
              middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with `HttpOptions`.
  app.addRoute(route, handler, HttpOptions, name, middlewares)

proc connect*(app: Prologue, route: string, handler: HandlerAsync, name = "",
              middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with `HttpConnect`.
  app.addRoute(route, handler, HttpConnect, name, middlewares)

proc patch*(app: Prologue, route: string, handler: HandlerAsync, name = "",
            middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with `HttpPatch`.
  app.addRoute(route, handler, HttpPatch, name, middlewares)

proc all*(app: Prologue, route: string, handler: HandlerAsync, name = "",
          middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with all `HttpMethod`.
  app.addRoute(route, handler, @[HttpGet, HttpPost, HttpPut, HttpDelete,
               HttpTrace, HttpOptions, HttpConnect, HttpPatch], name, middlewares)

# -------------------------------- Group Route --------------------------------

proc addGroup*(group: Group, route: string, handler: HandlerAsync,
               httpMethod = HttpGet, name = "", 
               middlewares: openArray[HandlerAsync] = @[]) =
  ## Adds a single route and handler. It checks whether route is duplicated.
  ## 
  ## Notes: The framework will automatically register `HttpHead` method, if
  ## `httpMethod` is `HttpGet`.
  let (route, middlewares) = getAllInfos(group, route, middlewares)
  group.app.addRoute(route, handler, httpMethod, name, middlewares)

proc addGroup*(group: Group, route: string, handler: HandlerAsync,
               httpMethod: openArray[HttpMethod], name = "", 
               middlewares: openArray[HandlerAsync] = @[]) =
  ## Adds a single regex `route` and `handler`, but supports a set of HttpMethod.
  ## It also checks whether route is duplicated
  let (route, middlewares) = getAllInfos(group, route, middlewares)
  group.app.addRoute(route, handler, httpMethod, name, middlewares)

proc addGroup*(app: Prologue, patterns: openArray[(Group, seq[UrlPattern])]) =
  ## Adds multiple routes with handlers.
  for (group, patterns) in patterns:
    for pattern in patterns:
      let (route, middlewares) = getAllInfos(group, pattern.route, @[])
      group.app.addRoute(route, pattern.matcher, pattern.httpMethod, 
                         pattern.name, middlewares)

proc head*(group: Group, route: string, handler: HandlerAsync, name = "",
           middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with `HttpHead`.
  let (route, middlewares) = getAllInfos(group, route, middlewares)
  group.app.addRoute(route, handler, HttpHead, name, middlewares)

proc get*(group: Group, route: string, handler: HandlerAsync, name = "",
          middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with `HttpGet` and `HttpHead`.
  let (route, middlewares) = getAllInfos(group, route, middlewares)
  group.app.addRoute(route, handler, HttpGet, name, middlewares)

proc post*(group: Group, route: string, handler: HandlerAsync, name = "",
           middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with `HttpPost`.
  let (route, middlewares) = getAllInfos(group, route, middlewares)
  group.app.addRoute(route, handler, HttpPost, name, middlewares)

proc put*(group: Group, route: string, handler: HandlerAsync, name = "",
          middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with `HttpPut`.
  let (route, middlewares) = getAllInfos(group, route, middlewares)
  group.app.addRoute(route, handler, HttpPut, name, middlewares)

proc delete*(group: Group, route: string, handler: HandlerAsync, name = "",
             middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with `HttpDelete`.
  let (route, middlewares) = getAllInfos(group, route, middlewares)
  group.app.addRoute(route, handler, HttpDelete, name, middlewares)

proc trace*(group: Group, route: string, handler: HandlerAsync, name = "",
            middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with `HttpTrace`.
  let (route, middlewares) = getAllInfos(group, route, middlewares)
  group.app.addRoute(route, handler, HttpTrace, name, middlewares)

proc options*(group: Group, route: string, handler: HandlerAsync, name = "",
              middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with `HttpOptions`.
  let (route, middlewares) = getAllInfos(group, route, middlewares)
  group.app.addRoute(route, handler, HttpOptions, name, middlewares)

proc connect*(group: Group, route: string, handler: HandlerAsync, name = "",
              middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with `HttpConnect`.
  let (route, middlewares) = getAllInfos(group, route, middlewares)
  group.app.addRoute(route, handler, HttpConnect, name, middlewares)

proc patch*(group: Group, route: string, handler: HandlerAsync, name = "",
            middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with `HttpPatch`.
  let (route, middlewares) = getAllInfos(group, route, middlewares)
  group.app.addRoute(route, handler, HttpPatch, name, middlewares)

proc all*(group: Group, route: string, handler: HandlerAsync, name = "",
          middlewares: openArray[HandlerAsync] = @[]) {.inline.} =
  ## Adds `route` and `handler` with all `HttpMethod`.
  let (route, middlewares) = getAllInfos(group, route, middlewares)
  group.app.addRoute(route, handler, @[HttpGet, HttpPost, HttpPut, HttpDelete,
               HttpTrace, HttpOptions, HttpConnect, HttpPatch], name, middlewares)

proc shutDownHandler() {.noconv.} =
  # shutdown events

  when defined(windows) and compileOption("threads"):
    # workaround for https://github.com/nim-lang/Nim/issues/4057
    setupForeignThreadGC()

  for event in dontUseThisShutDownEvents:
    execEvent(event)

  echo "Shutting down Events are done after having received SIGINT!\n"
  quit(QuitSuccess)

func use*(app: var Prologue, middlewares: varargs[HandlerAsync]) {.inline.} =
  app.middlewares.add middlewares

func newApp*(
  settings: Settings = newSettings(), 
  middlewares: openArray[HandlerAsync] = @[],
  startup: openArray[Event] = @[], 
  shutdown: openArray[Event] = @[],
  errorHandlerTable = newErrorHandlerTable({Http404: default404Handler, Http500: default500Handler}),
  appData = newStringTable(mode = modeCaseSensitive)
): Prologue {.inline.} =
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
    raise newException(ValueError, "Settings can't be empty!")
  result = newPrologue(settings = settings, ctxSettings = newCtxSettings(),
                       router = newRouter(), reversedRouter = newReversedRouter(),
                       reRouter = newReRouter(), middlewares = middlewares,
                       startup = startup, shutdown = shutdown,
                       errorHandlerTable = errorHandlerTable, appData = appData)

proc newAppQueryEnv*(
  configFileExt: ConfigFileExt,
  loadJsonNode: proc (configPath: string): JsonNode,
  middlewares: openArray[HandlerAsync] = @[],
  startup: openArray[Event] = @[], 
  shutdown: openArray[Event] = @[],
  errorHandlerTable = newErrorHandlerTable({Http404: default404Handler, Http500: default500Handler}),
  appData = newStringTable(mode = modeCaseSensitive)
): Prologue =
  ## Creates a new App instance.
  ## The config file used to create the instance is loaded from a `./.config` directory. 
  ## The specific config file of that directory that is used is determined by querying 
  ## the contents of the `PROLOGUE` environment variable, which must be set.
  let path = getPrologueEnv()

  var configPath: string
  if path.len == 0 or path == "default":
    configPath = fmt".config/config.{configFileExt}"
  else:
    configPath = fmt".config/config.{path}.{configFileExt}"

  if not dirExists(".config"):
    raise newException(IOError, "`.config` directory doesn't exist in the current path!")

  if not fileExists(configPath):
    raise newException(IOError, fmt"`{configPath}` file doesn't exist in the current path!")

  result = newPrologue(settings = loadSettings(loadJsonNode(configPath)), ctxSettings = newCtxSettings(),
                       router = newRouter(), reversedRouter = newReversedRouter(),
                       reRouter = newReRouter(), middlewares = middlewares,
                       startup = startup, shutdown = shutdown,
                       errorHandlerTable = errorHandlerTable, appData = appData)

proc newAppQueryEnv*(
  middlewares: openArray[HandlerAsync] = @[],
  startup: openArray[Event] = @[], 
  shutdown: openArray[Event] = @[],
  errorHandlerTable = newErrorHandlerTable({Http404: default404Handler, Http500: default500Handler}),
  appData = newStringTable(mode = modeCaseSensitive)
): Prologue {.inline.} =
  ## Creates a new App instance. by querying environment variables: `PROLOGUE`.
  newAppQueryEnv(ConfigFileExt.Json, parseFile)

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
  except Exception as e:
    logging.error(&"Malformed form params:\n{e.msg}")

proc handleContext*(app: Prologue, ctx: Context) {.async, gcsafe.} =
  ## Handles the context of each request.
  ## Todo Optimization
  ctx.middlewares = app.middlewares
  logging.debug(fmt"{ctx.request.reqMethod} {ctx.request.url.path}")

  try:
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
    logging.error $e.name & ": " & e.msg 
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

proc handleRequest*(app: Prologue, nativeRequest: NativeRequest, ctxTyp: typedesc[Context]): Future[void] {.gcsafe.} =
  ## Handles the native request and sends response to the client.
  var request = initRequest(nativeRequest)
  handleNativeRequest(request)

  var ctx = new ctxTyp
  init(ctx, request, initResponse(HttpVer11, Http200), app.gScope)
  extend(ctx)
  result = handleContext(app, ctx)

proc prepareRun(app: Prologue) =
  # assert ctx != nil, "The memory of `ctx` must be allocated!"
  app.gScope.router.compress()

  # start event
  app.execStartupEvent()

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
      logging.debug(fmt"Prologue is serving at http://127.0.0.1:{app.appPort} {app.appName}")
    else:
      logging.debug(fmt"Prologue is serving at http://0.0.0.0:{app.appPort} {app.appName}")
  else:
    logging.debug(fmt"Prologue is serving at http://{app.appAddress}:{app.appPort} {app.appName}")

proc run*(app: Prologue, ctxTyp: typedesc[Context]) =
  ## Starts an Application.

  prepareRun(app)

  proc handler(nativeRequest: NativeRequest): Future[void] {.gcsafe.} =
    result = handleRequest(app, nativeRequest, ctxTyp)

  app.serve(handler)

proc run*(app: Prologue) {.inline.} =
  app.run(Context)

proc runAsync*(app: Prologue, ctxTyp: typedesc[Context]) {.async.} =
  ## Starts an Application.

  prepareRun(app)

  proc handler(nativeRequest: NativeRequest): Future[void] {.gcsafe.} =
    result = handleRequest(app, nativeRequest, ctxTyp)

  await app.serveAsync(handler)

proc runAsync*(app: Prologue) {.inline, async.} =
  await app.runAsync(Context)


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
  # app.serveDocs()
  app.run()
