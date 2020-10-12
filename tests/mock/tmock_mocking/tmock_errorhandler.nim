import ../../../src/prologue
import ../../../src/prologue/mocking

import std/uri


proc go404(ctx: Context) {.async.} =
  ctx.response.body = "Something wrong!"

proc hello(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc helloError(ctx: Context) {.async.} =
  resp error404(Http404, "This is test!")

proc helloDefaultError(ctx: Context) {.async.} =
  ctx.ctxData["Tested"] = "true"
  respDefault Http404

proc prepareApp(debug = true): Prologue =
  result = newApp(settings = newSettings(debug = debug))
  mockApp(result)

proc addTestRoute(app: Prologue, path: string, httpMethod = HttpGet) =
  app.addRoute(path, hello, httpMethod)

proc prepareRequest(path: string, httpMethod = HttpGet): Request =
  result = initMockingRequest(
    httpMethod = httpMethod,
    headers = newHttpHeaders(),
    url = parseUri(path),
    cookies = initCookieJar(),
    postParams = newStringTable(),
    queryParams = newStringTable(),
    formParams = initFormPart(),
    pathParams = newStringTable()
  )

proc testError404(app: Prologue, path: string, httpMethod = HttpGet, body = "Something wrong!"): Context =
  result = app.runOnce(prepareRequest(path, httpMethod))
  doAssert result.response.code == Http404, $result.response.code
  doAssert result.response.body == body, result.response.body


block ErrorHandler:
  # No find handler
  block:
    var app = prepareApp()
    app.registerErrorHandler(Http404, go404)
    app.addTestRoute("/hello")
    discard testError404(app, "/no")

  block:
    # Http 404
    var app = prepareApp()
    app.registerErrorHandler(Http404, go404)
    app.addRoute("/hello", helloDefaultError)
    let ctx = testError404(app, "/hello")
    doAssert ctx.ctxData["Tested"] == "true"

  block:
    var app = prepareApp()
    app.registerErrorHandler(Http404, go404)
    app.addRoute("/hello", helloError)
    discard testError404(app, "/hello", body = "This is test!")

  block:
    proc go500(ctx: Context) {.async.} = 
      ctx.response.code = Http500
      ctx.response.body = "Internal Error"

    var app = prepareApp(debug = true)
    app.addRoute("/hello", go500)
    let ctx = app.runOnce(prepareRequest("/hello"))
    doAssert ctx.response.body == "Internal Error"

  block:
    proc go500(ctx: Context): Future[void] = 
      if true:
        raise newException(ValueError, "This is wrong!")

    var app = prepareApp(debug = true)
    app.addRoute("/hello", go500)
    let ctx = app.runOnce(prepareRequest("/hello"))
    doAssert ctx.response.body != "This is wrong!"

  block:
    proc go500(ctx: Context) {.async.} = 
      ctx.response.code = Http500
      ctx.response.body = "Internal Error"

    var app = prepareApp(debug = false)
    app.addRoute("/hello", go500)
    let ctx = app.runOnce(prepareRequest("/hello"))
    doAssert ctx.response.body == internalServerErrorPage(), ctx.response.body

  block:
    proc go500(ctx: Context): Future[void] = 
      if true:
        raise newException(ValueError, "This is wrong!")

    var app = prepareApp(debug = false)
    app.addRoute("/hello", go500)
    let ctx = app.runOnce(prepareRequest("/hello"))
    doAssert ctx.response.body == internalServerErrorPage()

  block:
    proc go500(ctx: Context) {.async.} = 
      ctx.response.code = Http500
      ctx.response.body.setLen(0)

    var app = prepareApp(debug = true)
    app.addRoute("/hello", go500)
    let ctx = app.runOnce(prepareRequest("/hello"))
    doAssert ctx.response.body == internalServerErrorPage()

  block:
    proc go500(ctx: Context): Future[void] = 
      if true:
        raise newException(ValueError, "")

    var app = prepareApp(debug = true)
    app.addRoute("/hello", go500)
    let ctx = app.runOnce(prepareRequest("/hello"))
    doAssert ctx.response.body.len > 0
    doAssert ctx.response.body != internalServerErrorPage()

  block:
    proc go500(ctx: Context) {.async.} = 
      ctx.response.code = Http500
      ctx.response.body.setLen(0)

    var app = prepareApp(debug = false)
    app.addRoute("/hello", go500)
    let ctx = app.runOnce(prepareRequest("/hello"))
    doAssert ctx.response.body == internalServerErrorPage(), ctx.response.body

  block:
    proc go500(ctx: Context): Future[void] = 
      if true:
        raise newException(ValueError, "")

    var app = prepareApp(debug = false)
    app.addRoute("/hello", go500)
    let ctx = app.runOnce(prepareRequest("/hello"))
    doAssert ctx.response.body == internalServerErrorPage()
