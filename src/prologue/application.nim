import asyncdispatch, uri, cgi, httpcore, cookies
import tables, strutils, strformat, macros, logging, strtabs
import request, response, context, server, middlewares, pages, route, nativesettings, parseutils


export httpcore
export strtabs
export asyncdispatch
export middlewares
export pages
export request
export response
export context
export server
export pattern
export nativesettings


proc addRoute*(app: Prologue, route: string, handler: Handler,
    httpMethod = HttpGet, middlewares: seq[MiddlewareHandler] = @[]) {.inline.} =
  let path = initPath(route = route,
      httpMethod = httpMethod)
  if path in app.router.callable:
    raise newException(DuplicatedRouteError, fmt"Route {route} is duplicated!")
  app.router.callable[path] = newPathHandler(handler, middlewares)

proc addRoute*(app: Prologue, patterns: seq[UrlPattern],
    baseRoute = "") =
  for pattern in patterns:
    app.addRoute(baseRoute & pattern.route, pattern.handler, pattern.httpMethod,
        pattern.middlewares)

proc addRoute*(app: Prologue, urlFile: string, baseRoute = "") =
  discard

proc findHandler(app: Prologue, ctx: Context, path: Path): PathHandler =
  if path in app.router.callable:
    return app.router.callable[path]
  let
    path = path.route
    pathList = path.split("/")

  for route, handler in app.router.callable.pairs:
    let routeList = route.route.split("/")
    var flag = true
    if pathList.len == routeList.len:
      for idx in 0 ..< pathList.len:
        if pathList[idx] == routeList[idx]:
          continue
        if routeList[idx].startsWith("{"):
          # should be checked in addRoute
          let key = routeList[idx]
          if key.len <= 2:
            raise newException(RouteError, "{} shouldn't be empty!")
          ctx.request.pathParams[key[1 .. ^2]] = decodeUrl(pathList[idx])
        else:
          flag = false
          break
      if flag:
        return handler
  return newPathHandler(defaultHandler)

macro resp*(params: string) =
  var ctx = ident"ctx"
  # let response = ident"response"

  result = quote do:
    `ctx`.response.body = `params`
    asyncCheck handle(`ctx`)
    logging.debug($(`ctx`.response))

macro resp*(params: Response) =
  var ctx = ident"ctx"
  # let response = ident"response"

  result = quote do:
    `ctx`.response = `params`
    asyncCheck handle(`ctx`)
    logging.debug($(`ctx`.response))

proc initApp*(settings: Settings, middlewares: seq[MiddlewareHandler] = @[]): Prologue =
  Prologue(server: newPrologueServer(true, settings.reusePort),
      settings: settings, router: newRouter(), middlewares: middlewares)

proc run*(app: Prologue) =
  proc handleRequest(nativeRequest: NativeRequest) {.async.} =
    var request = initRequest(nativeRequest = nativeRequest, settings = app.settings)
    let
      # /student?name=simon&age=sixteen
      # query -> name=simon&age=sixteen
      urlQuery = request.query # string
      headers = request.headers

    if headers.hasKey("cookies"):
      request.cookies = headers["cookies", 0].parseCookies

    var contentType: string
    if headers.hasKey("content-type"):
      contentType = headers["content-type", 0]

    # get or post forms params
    if "form-urlencoded" in contentType:
      for (key, value) in decodeData(request.body):
        case request.reqMethod
        of HttpGet:
          request.getParams[key] = value
        of HttpPost:
          request.postParams[key] = value
        else:
          discard

    elif "multipart/form-data" in contentType and "boundary" in contentType:
      let 
        sep = contentType[contentType.rfind("boundary") + 9 .. ^1]
        startSep = fmt"--{sep}"
        endSep = fmt"--{sep}--"
        body = request.body
        startPos = find(body, startSep)
        endPos = rfind(body, endSep)
        formData = body[startPos ..< endPos]
        formDataSeq = formData.split(startSep & "\c\L")

      var 
        multiPartForm: MultiPartForm

      for data in formDataSeq:
        if data.len == 0:
          continue
        var formPart: FormPart
        for line in data.splitLines:
          if line.startsWith("Content-Disposition"):
            var 
              pos = 0
              times = 0
              tok = ""
              formKey, formValue: string
            let
              content = line.parseHeader.value[0]
              length = content.len
            pos += parseUntil(content, tok, ';', pos)
            doAssert tok == "form-data", fmt"{tok} != form-data"

            while pos < length:
              pos += skipWhile(content, {';', ' '}, pos)
              pos += parseUntil(content, formKey, '=', pos)
              pos += skipWhile(content, {'=', '\"'}, pos)
              pos += parseUntil(content, formValue, '\"', pos)
              pos += skipWhile(content, {'\"'}, pos)
              case formKey
              of "name":
                formPart.name = formValue
              of "filename":
                formPart.filename = formValue
              of "filename*":
                formPart.filenamestar = formValue
              else:
                discard
              times += 1
              if times >= 3:
                break
          elif line.len > 0:
            formPart.value = line
          else:
            discard
        multiPartForm.add formPart
    

    for (key, value) in decodeData(urlQuery):
      request.queryParams[key] = value

    var response = initResponse(HttpVer11, Http200, httpHeaders = {
        "Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders)
    var ctx = newContext(request = request, response = response)

    # gcsafe
    for middlewareHandler in app.middlewares:
      if middlewareHandler(ctx):
        await handle(ctx)
        return

    logging.debug(fmt"{ctx.request.reqMethod} {ctx.request.url.path}")
    let path = initPath(route = ctx.request.url.path,
        httpMethod = ctx.request.reqMethod)
    # gcsafe
    let pathHandler = app.findHandler(ctx, path)
    for middlewareHandler in pathHandler.middlewares:
      if middlewareHandler(ctx):
        await handle(ctx)
        return
    await pathHandler.handler(ctx)

  # maybe should read settings from file
  if logging.getHandlers().len == 0:
    addHandler(logging.newConsoleLogger())
    setLogFilter(if app.settings.debug: lvlInfo else: lvlDebug)
  defer: app.close()
  when defined(windows):
    logging.info(fmt"Prologue is serving at 127.0.0.1:{app.settings.port.int} {app.settings.appName}")
  else:
    logging.info(fmt"Prologue is serving at 0.0.0.0:{app.settings.port.int} {app.settings.appName}")
  waitFor app.serve(app.settings.port, handleRequest)


when isMainModule:
  proc hello*(ctx: Context) {.async.} =
    resp "<h1>Hello, Prologue!</h1>"

  proc home*(ctx: Context) {.async.} =
    resp "<h1>Home</h1>"

  proc helloName*(ctx: Context) {.async.} =
    resp "<h1>Hello, " & ctx.request.pathParams.getOrDefault("name",
        "Prologue") & "</h1>"

  proc testRedirect*(ctx: Context) {.async.} =
    resp redirect("/hello")

  proc login*(ctx: Context) {.async.} =
    resp loginPage()

  proc do_login*(ctx: Context) {.async.} =
    resp redirect("/hello/Nim")

  let settings = newSettings(appName = "StarLight")
  var app = initApp(settings = settings, middlewares = @[debugRequestMiddleware])
  app.addRoute("/", home, HttpGet)
  app.addRoute("/", home, HttpPost)
  app.addRoute("/home", home, HttpGet)
  app.addRoute("/hello", hello, HttpGet)
  app.addRoute("/redirect", testRedirect, HttpGet)
  app.addRoute("/login", login, HttpGet)
  app.addRoute("/login", do_login, HttpPost, @[debugRequestMiddleware])
  app.addRoute("/hello/{name}", helloName, HttpGet)
  app.run()
