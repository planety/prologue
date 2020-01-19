import asynchttpserver, asyncdispatch, uri, cookies, httpcore, httpclient
import tables, strutils, strformat, macros, logging, hashes, strtabs



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
    staticDir: string
    appName: string

  Request* = ref object
    nativeRequest*: NativeRequest
    params*: StringTableRef
    settings: Settings
    cookies: StringTableRef

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

proc abort*(request: Request, status = Http401, body = "") {.async.} =
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

proc defaultHandler*(request: Request) {.async.} =
  await error404(request)

proc findHandler*(app: Prologue, request: Request, path: Path): Handler =
  if path in app.router.callable:
    return app.router.callable[path]
  let
    path = path.basePath & path.route
    pathList = path.split("/")

  var flag = true

  for route, handler in app.router.callable.pairs:
    let routeList = (route.basePath & route.route).split("/")
    if pathList.len == routeList.len:
      for idx in 0 ..< pathList.len:
        if pathList[idx] == routeList[idx]:
          continue
        if routeList[idx].startsWith("{"):
          # should be checked in addRoute
          let key = routeList[idx]
          if key.len <= 2:
            raise newException(RouteError, "{} shouldn't be empty!")
          request.params[key[1 .. ^2]] = pathList[idx]
        else:
          flag = false
          break
      if flag:
        return handler
  return defaultHandler

proc handle*(request: Request, response: Response) {.async.} =
  await request.nativeRequest.respond(response.status, response.body,
      response.httpHeaders)

proc `$`*(response: Response): string =
  fmt"{response.status} {response.httpHeaders}"

macro resp*(params: typed) =
  let request = ident"request"
  # let response = ident"response"
  # echo getTypeInst(params).repr
  result = quote do:
    var response = newResponse(HttpVer11, Http200, httpHeaders = {
        "Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders,
        body = $`params`)
    asyncCheck handle(`request`, response)
    logging.debug($response)

proc initSettings*(port = Port(8080), debug = false, reusePort = true,
    staticDir = "/static", appName = ""): Settings =
  Settings(port: port, debug: debug, reusePort: reusePort, staticDir: staticDir,
      appName: appName)

proc initApp*(settings: Settings): Prologue =
  Prologue(server: newAsyncHttpServer(true, settings.reusePort),
      settings: settings, router: newRouter())

proc run*(app: Prologue) =
  proc handleRequest(nativeRequest: NativeRequest) {.async.} =
    var request = Request(nativeRequest: nativeRequest, params: newStringTable(
      ), settings: app.settings, cookies: newStringTable())

    logging.debug(fmt"{request.nativeRequest.reqMethod} {request.nativeRequest.url.path}")
    let path = initPath(route = request.nativeRequest.url.path, basePath = "",
    httpMethod = request.nativeRequest.reqMethod)
    {.gcsafe.}:
      let handler = app.findHandler(request, path)
      await handler(request)

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
    resp "<h1>Hello, " & request.params.getOrDefault("name", "Prologue") & "</h1>"

  proc testRedirect*(request: Request) {.async.} =
    await redirect(request, "/hello")

  let settings = initSettings(appName = "StarLight")
  var app = initApp(settings = settings)
  app.addRoute("/", home, "", HttpGet)
  app.addRoute("/", home, "", HttpPost)
  app.addRoute("/home", home, "", HttpGet)
  app.addRoute("/hello", hello, "", HttpGet)
  app.addRoute("/redirect", testRedirect, "", HttpGet)
  # app.addRoute("/hello", hello, "advanced"， HttpGet)
  # app.addRoute("/templ", templ, "tempalte", HttpGet)
  app.addRoute("/hello/{name}", helloName, "", HttpGet)
  app.run()
