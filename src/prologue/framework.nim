import asynchttpserver, asyncdispatch, uri, httpcore, httpclient
import tables, strutils, strformat, macros, logging, parseutils



type
  NativeRequest = asynchttpserver.Request
  PrologueError* = object of Exception
  RouteError* = object of PrologueError
  RouteResetError* = object of RouteError
  DuplicatedRouteError* = object of RouteError

  Settings* = object
    port: Port
    debug: bool
    reusePort: bool
    appName: string

  Request* = ref object
    nativeRequest: NativeRequest
    params*: Table[string, string]
    settings: Settings

  Response* = ref object
    httpVersion*: HttpVersion
    status*: HttpCode
    httpHeaders*: HttpHeaders
    body*: string

  Handler* = proc(request: Request): Future[void]

  Path* = object
    basePath*: string
    handler*: Handler
    path*: string

  Router* = ref object
    callable*: Table[string, Handler]
    httpMethod*: HttpMethod

  Prologue* = object
    server: AsyncHttpServer
    settings: Settings
    router: Router


proc newResponse*(httpVersion: HttpVersion, status: HttpCode,
    httpHeaders = newHttpHeaders(), body = ""): Response =
  Response(httpVersion: httpVersion, status: status, httpHeaders: httpHeaders, body: body)

proc abortWith*(status = Http404, body = ""): Response =
  result = newResponse(httpVersion = HttpVer11, status = status, body = body)

proc redirectTo*(status = Http301, url: string,
    body = "", delay = 0): Response =
  result = newResponse(httpVersion = HttpVer11, status = status, body = body)

  if delay == 0:
    result.httpHeaders.add("Location", url)
  else:
    result.httpHeaders.add("refresh", fmt"""{delay};url="{url}"""")

proc error*(status = Http404, body = "<h1>404 Not Found!</h1>"): Response =
  newResponse(httpVersion = HttpVer11, status = status, body = body)

proc newRouter*(): Router =
  Router(callable: initTable[string, Handler]())

proc addRoute*(app: Prologue, route: string, handler: Handler,
    httpMethod = HttpGet) =
  if route in app.router.callable:
    raise newException(DuplicatedRouteError, fmt"Route {route} is duplicated!")
  app.router.callable[route] = handler
  app.router.httpMethod = httpMethod


proc findHandler*(app: Prologue, request: Request): bool =
  let path = request.nativeRequest.url.path
  if path in app.router.callable:
    return true
  return false

proc handle*(request: Request, response: Response) {.async.} =
  await request.nativeRequest.respond(response.status, response.body,
      response.httpHeaders)

proc `$`*(response: Response): string =
  fmt"{response.status} {response.httpHeaders}"

macro resp*(params: untyped) =
  let request = ident"request"
  # let response = ident"response"
  result = quote do:
    var response = newResponse(HttpVer11, Http200, body = $`params`)
    asyncCheck handle(`request`, response)
    logging.debug($response)

proc initSettings*(port = Port(8080), debug = false, reusePort = true,
    appName = ""): Settings =
  Settings(port: port, debug: debug, reusePort: reusePort, appName: appName)

proc initApp*(settings: Settings): Prologue =
  Prologue(server: newAsyncHttpServer(true, settings.reusePort),
      settings: settings, router: newRouter())

proc run*(app: Prologue) =
  proc handleRequest(nativeRequest: NativeRequest) {.async.} =
    var request = Request(nativeRequest: nativeRequest, params: initTable[
        string, string](), settings: app.settings)

    logging.debug(fmt"{request.nativeRequest.reqMethod} {request.nativeRequest.url.path}")
    if app.findHandler(request):
      {.gcsafe.}:
        let handler = app.router.callable[request.nativeRequest.url.path]
        await handler(request)
    else:
      let response = error(status = Http404, body = "<h1>404 Not Found!</h1>")
      await request.nativeRequest.respond(response.status, response.body,
          response.httpHeaders)
      logging.debug($response)

  # maybe should read settings from file
  if logging.getHandlers().len == 0:
    addHandler(logging.newConsoleLogger())
    setLogFilter(if app.settings.debug: lvlInfo else: lvlDebug)
  defer: app.server.close()
  logging.info(fmt"Prologue is serving at 127.0.0.1:{app.settings.port.int} {app.settings.appName}")
  waitFor app.server.serve(app.settings.port, handleRequest)


when isMainModule:
  proc hello*(request: Request) {.async.} =
    resp "<h1>Hello, Prologue!</h1>"

  proc home*(request: Request) {.async.} =
    resp "<h1>Home</h1>"

  proc templ*(request: Request) {.async.} =
    resp {"name": "string"}.toTable

  proc helloName*(request: Request) {.async.} =
    resp "Hello, " & request.params["name"]

  let settings = initSettings(appName = "Test")
  var app = initApp(settings = settings)
  app.addRoute("/", home, HttpGet)
  app.addRoute("/home", home, HttpGet)
  app.addRoute("/hello", hello, HttpGet)
  # app.addRoute("/hello", hello, HttpGet)
  # app.addRoute("/templ", templ, HttpGet, render = "templ.html")
  # app.addRoute("/hello/<name>", HttpGet, helloName)
  app.run()
