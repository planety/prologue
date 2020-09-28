import ../../src/prologue
import ../../src/prologue/mocking/mocking

import uri, segfaults


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"


proc prepareApp*(debug = true): Prologue =
  result = newApp(settings = newSettings(debug = debug))
  mockApp(result)

proc addTestRoute*(app: Prologue, path: string, httpMethod = HttpGet) =
  app.addRoute(path, hello, httpMethod)

proc prepareRequest(path: string, httpMethod: HttpMethod): Request =
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


proc testContext(app: Prologue, path: string, httpMethod = HttpGet): Context =
  result = app.runOnce(prepareRequest(path, httpMethod))
  doAssert result.response.code == Http200
  doAssert result.response.getHeader("content-type") == @["text/html; charset=UTF-8"]
  doAssert result.response.body == "<h1>Hello, Prologue!</h1>"


block Basic_Mapping:
  #test "Root":
  block:
    var app = prepareApp()
    app.addTestRoute("/")
    discard testContext(app, "/")

  # test "Multiple mappings with a root":
  block:
    var app = prepareApp()
    app.addTestRoute("/")
    app.addTestRoute("/foo/bar")
    app.addTestRoute("/baz")
    discard testContext(app, "/")
    discard testContext(app, "/foo/bar")
    discard testContext(app, "/baz")

  # test "Multiple mappings without a root":
  block:
    var app = prepareApp()
    app.addTestRoute("/foo/bar")
    app.addTestRoute("/baz")
    discard testContext(app, "/foo/bar")
    discard testContext(app, "/baz")

  # test "Duplicate root":
  block:
    var app = prepareApp()
    app.addTestRoute("/")
    discard testContext(app, "/")

    doAssertRaises(DuplicatedRouteError):
      app.addTestRoute("/")

  # test "Ends with wildcard":
  block:
    var app = prepareApp()
    app.addTestRoute("/*")
    discard testContext(app, "/wildcard")

  # test "Ends with param":
  block:
    var app = prepareApp()
    app.addTestRoute("/{param}")
    let ctx = testContext(app, "/value")
    doAssert ctx.getPathParams("param") == "value"

  # test "Wildcard in middle":
  block:
    var app = prepareApp()
    app.addTestRoute("/*/test")
    discard testContext(app, "/wildcard/test")

  # test "Param in middle":
  block:
    var app = prepareApp()
    app.addTestRoute("/{param}/test")
    let ctx = testContext(app, "/value/test")
    doAssert ctx.getPathParams("param") == "value"

  # test "Param + wildcard":
  block:
    var app = prepareApp()
    app.addTestRoute("/{param}/*")
    let ctx = testContext(app, "/value/test")
    doAssert ctx.getPathParams("param") == "value"

  # test "Wildcard + param":
  block:
    var app = prepareApp()
    app.addTestRoute("/*/{param}")
    let ctx = testContext(app, "/somevalue/value")
    doAssert ctx.getPathParams("param") == "value"

  # test "Trailing slash has no effect":
  block:
    var app = prepareApp()
    app.addTestRoute("/flywind/prologue")
    discard testContext(app, "/flywind/prologue")
    discard testContext(app, "/flywind/prologue/")
