import ../../src/prologue
import ../../src/prologue/mocking/mocking

import uri


proc prepareApp*(debug = true): Prologue =
  result = newApp(settings = newSettings(debug = debug))
  mockApp(result)


proc prepareRequest*(path: string, httpMethod = HttpGet): Request =
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
  proc hello(ctx: Context) {.async.} =
    ctx.ctxData["test"] = "true"
    resp "Something is wrong, please retry.", Http404

  var app = prepareApp()
  app.addRoute("/hello", hello)
  let ctx = app.runOnce(prepareRequest("/hello"))
  doAssert ctx.ctxData["test"] == "true"
