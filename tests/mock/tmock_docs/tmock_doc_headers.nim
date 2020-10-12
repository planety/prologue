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


block first:
  proc hello(ctx: Context) {.async.} =
    if ctx.request.hasHeader("cookie"):
      let values = ctx.request.getHeader("cookie")
      resp $values
    elif ctx.request.hasHeader("content-type"):
      let values = ctx.request.getHeaderOrDefault("content")
      resp $values

  block:
    var app = prepareApp()
    app.addRoute("/hello", hello)
    var req = prepareRequest("/hello")
    req.addHeader("cookie", "name=prologue&value=nim")
    let ctx = app.runOnce(req)
    doAssert ctx.response.body == "@[\"name=prologue&value=nim\"]", ctx.response.body
  
  block:
    var app = prepareApp()
    app.addRoute("/hello", hello)
    var req = prepareRequest("/hello")
    req.addHeader("content-type", "text")
    let ctx = app.runOnce(req)
    doAssert ctx.response.body == "@[\"\"]", ctx.response.body


block second:
  proc hello(ctx: Context) {.async.} =
    ctx.ctxData["test"] = "true"

    ctx.response.addHeader("Content-Type", "text/plain")

    doAssert ctx.response.getHeader("CONTENT-TYPE") == @[
          "text/html; charset=UTF-8", "text/plain"]

    ctx.response.setHeader("Content-Type", "text/plain")

    doAssert ctx.response.getHeader("CONTENT-TYPE") == @[
        "text/html; charset=UTF-8", "text/plain"]

  var app = prepareApp()
  app.addRoute("/hello", hello)
  let ctx = app.runOnce(prepareRequest("/hello"))
  doAssert ctx.ctxData["test"] == "true"
