import ../../../src/prologue
import ../../../src/prologue/mocking

import std/uri


proc prepareApp(debug = true): Prologue =
  result = newApp(settings = newSettings(debug = debug))
  mockApp(result)

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

block:
  block first:
    proc hello(ctx: Context) {.async.} =
      ctx.ctxData["test"] = "true"
      resp "Something is wrong, please retry.", Http404

    var app = prepareApp()
    app.addRoute("/hello", hello)
    let ctx = app.runOnce(prepareRequest("/hello"))
    doAssert ctx.ctxData["test"] == "true"
    doAssert ctx.response.code == Http404
    doAssert ctx.response.body == "Something is wrong, please retry."

  block second:
    proc hello(ctx: Context) {.async.} =
      ctx.ctxData["test"] = "true"
      resp error404(headers = ctx.response.headers)

    var app = prepareApp()
    app.addRoute("/hello", hello)
    let ctx = app.runOnce(prepareRequest("/hello"))
    doAssert ctx.ctxData["test"] == "true"
    doAssert ctx.response.code == Http404
    doAssert ctx.response.body == "<h1>404 Not Found!</h1>"

  block three:
    proc hello(ctx: Context) {.async.} =
      ctx.ctxData["test"] = "true"
      resp errorPage("Something is wrong"), Http404

    var app = prepareApp()
    app.addRoute("/hello", hello)
    let ctx = app.runOnce(prepareRequest("/hello"))
    doAssert ctx.ctxData["test"] == "true"
    doAssert ctx.response.code == Http404
    doAssert ctx.response.body == errorPage("Something is wrong")

  block four:
    proc hello(ctx: Context) {.async.} =
      ctx.ctxData["test"] = "true"
      respDefault(Http404)

    let settings = newSettings(appName = "Prologue")
    var app = newApp(settings)
    mockApp(app)
    app.addRoute("/hello", hello)
    let ctx = app.runOnce(prepareRequest("/hello"))
    doAssert ctx.ctxData["test"] == "true"
    doAssert ctx.response.code == Http404
    doAssert ctx.response.body == errorPage("404 Not Found!"), ctx.response.body

  block five:
    proc hello(ctx: Context) {.async.} =
      ctx.ctxData["test"] = "true"
      respDefault(Http404)

    var app = newApp(errorHandlerTable = newErrorHandlerTable())
    mockApp(app)
    app.addRoute("/hello", hello)
    let ctx = app.runOnce(prepareRequest("/hello"))
    doAssert ctx.ctxData["test"] == "true"
    doAssert ctx.response.code == Http404
    doAssert ctx.response.body.len == 0
