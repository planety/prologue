import asynchttpserver, asyncdispatch, uri, httpcore, httpclient
import tables, strutils, strformat, macros, logging, parseutils, hashes



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
    route: string
    basePath: string
    httpMethod*: HttpMethod

  Router* = ref object
    callable*: Table[Path, Handler]

  Prologue* = object
    server: AsyncHttpServer
    settings: Settings
    router: Router

proc initPath*(route: string, basePath = "", httpMethod = HttpGet): Path =
  Path(route: route, basePath: basePath, httpMethod: httpMethod)

proc hash*(x: Path): Hash =
  var h: Hash = 0
  h = h !& hash(x.basePath & x.route)
  h = h !& hash(x.httpMethod)
  result = !$h

proc newResponse*(httpVersion: HttpVersion, status: HttpCode,
    httpHeaders = newHttpHeaders(), body = ""): Response =
  Response(httpVersion: httpVersion, status: status, httpHeaders: httpHeaders, body: body)

proc newRouter*(): Router =
  Router(callable: initTable[Path, Handler]())

proc addRoute*(app: Prologue, route: string, handler: Handler, basePath = "",
    httpMethod = HttpGet) =
  let path = initPath(route = route, basePath = basePath,
      httpMethod = httpMethod)
  if path in app.router.callable:
    raise newException(DuplicatedRouteError, fmt"Route {route} is duplicated!")
  app.router.callable[path] = handler

proc addRoute*(app: Prologue, basePath: string, fileName: string) =
  discard

proc findHandler*(app: Prologue, request: Request, path: Path): bool =
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

proc abortWith*(request: Request, status = Http404, body = "") {.async.} =
  await request.nativeRequest.respond(status, body)
  logging.debug($status)

proc redirect*(request: Request, url: string, status = Http301,
    body = "", delay = 0) {.async.} =

  var headers = newHttpHeaders()
  if delay == 0:
    headers.add("Location", url)
  else:
    headers.add("refresh", fmt"""{delay};url="{url}"""")
  await request.nativeRequest.respond(status, body, headers)
  logging.debug(fmt"{status} {headers}")

proc error404*(request: Request, status = Http404,
    body = "<h1>404 Not Found!</h1>") {.async.} =
  await request.nativeRequest.respond(status, body)
  logging.debug($status)

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
    let path = initPath(route = request.nativeRequest.url.path, basePath = "",
    httpMethod = request.nativeRequest.reqMethod)
    if app.findHandler(request, path):
      {.gcsafe.}:
        let handler = app.router.callable[path]
        await handler(request)
    else:
      await error404(request)

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

  proc testRedirect*(request: Request) {.async.} =
    await redirect(request, "/hello")

  let settings = initSettings(appName = "Test")
  var app = initApp(settings = settings)
  app.addRoute("/", home, "", HttpGet)
  app.addRoute("/home", home, "", HttpGet)
  app.addRoute("/hello", hello, "", HttpGet)
  app.addRoute("/redirect", testRedirect, "", HttpGet)
  # app.addRoute("/hello", hello, "advanced"， HttpGet)
  # app.addRoute("/templ", templ, "tempalte", HttpGet)
  # app.addRoute("/hello/<name>", helloName, "name", HttpGet, )
  app.run()
