import ../../../src/prologue
import ../../../src/prologue/mocking

import std/uri


proc hello(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"


proc prepareApp(debug = true): Prologue =
  result = newApp(settings = newSettings(debug = debug))
  mockApp(result)

proc addTestRoute(app: Prologue, path: string, httpMethod = HttpGet) =
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

proc testFailedContext(app: Prologue, path: string, httpMethod = HttpGet): Context =
  result = app.runOnce(prepareRequest(path, httpMethod))
  doAssert result.response.code == Http404


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

  # test "Trailing slash doesn't make a unique mapping":
  block:
    var app = prepareApp()
    app.addTestRoute("/some/url/")
    doAssertRaises(DuplicatedRouteError):
      app.addTestRoute("/some/url")

  # test "Varying param names don't make a unique mapping":
  block:
    var app = prepareApp()
    app.addTestRoute("/has/{paramA}")

    doAssertRaises(DuplicatedRouteError):
      app.addTestRoute("/has/{paramB}")

  # test "Param vs wildcard don't make a unique mapping":
  block:
    var app = prepareApp()
    app.addTestRoute("/has/{param}")

    doAssertRaises(DuplicatedRouteError):
      app.addTestRoute("/has/*")

  # test "Greedy params must go at the end of a mapping":
  block:
    var app = prepareApp()
    doAssertRaises(RouteError):
      app.addTestRoute("/has/{p1}$/{p2}")

  # test "Greedy wildcards must go at the end of a mapping":
  block:
    var app = prepareApp()
    doAssertRaises(RouteError):
      app.addTestRoute("/has/*$/*")

  # test "Wildcards only match one URL section":
  block:
    var app = prepareApp()
    app.addTestRoute("/has/*/one")
    discard testFailedContext(app, "/has/a/b/one")


  # test "Invalid characters in URL":
  block:
    var app = prepareApp()
    app.addTestRoute("/test/{param}")
    discard testFailedContext(app, "/test/!/")

  # test "Remaining path consumption with parameter":
  block:
    var app = prepareApp()
    app.addTestRoute("/test/{param}$")
    let ctx = testContext(app, "/test/foo/bar/baz/")
    doAssert ctx.getPathParams("param") == "foo/bar/baz"

  # test "Remaining path consumption with wildcard":
  block:
    var app = prepareApp()
    app.addTestRoute("/test/*$")
    discard testContext(app, "/test/foo/bar/baz")

  # test "Map sub path after path":
  block:
    var app = prepareApp()
    app.addTestRoute("/hello")
    app.addTestRoute("/")

  # test "Path param that consumes entire path":
  block:
    var app = prepareApp()
    app.addTestRoute("/{pathParam}$")
    discard testContext(app, "/foo/bar/baz")

  # test "Path param combined with consuming path param":
  block:
    var app = prepareApp()
    app.addTestRoute("/{pathParam1}/{pathParam2}$")
    discard testContext(app, "/foo/bar/baz")

  # test "Path param combined with consuming wildcard":
  block:
    var app = prepareApp()
    app.addTestRoute("/{pathParam}/*$")
    discard testContext(app, "/foo/bar/baz")

  # "Restful Function Test"
  block:
    # "restful head can work"
    block:
      var app = prepareApp()
      app.head("/hi", hello)
      discard testContext(app, "/hi", HttpHead)

  # "restful get can work"
  block:
    var app = prepareApp()
    app.get("/hi", hello)
    discard testContext(app, "/hi", HttpHead)
    discard testContext(app, "/hi", HttpGet)

  # "restful post can work"
  block:
    var app = prepareApp()
    app.post("/hi", hello)
    discard testContext(app, "/hi", HttpPost)

  # "restful put can work"
  block:
    var app = prepareApp()
    app.put("/hi", hello)
    discard testContext(app, "/hi", HttpPut)

  # "restful delete can work"
  block:
    var app = prepareApp()
    app.delete("/hi", hello)
    discard testContext(app, "/hi", HttpDelete)

  # "restful trace can work"
  block:
    var app = prepareApp()
    app.trace("/hi", hello)
    discard testContext(app, "/hi", HttpTrace)

  # "restful options can work"
  block:
    var app = prepareApp()
    app.options("/hi", hello)
    discard testContext(app, "/hi", HttpOptions)

  # "restful connect can work"
  block:
    var app = prepareApp()
    app.connect("/hi", hello)
    discard testContext(app, "/hi", HttpConnect)

  # "restful patch can work"
  block:
    var app = prepareApp()
    app.patch("/hi", hello)
    discard testContext(app, "/hi", HttpPatch)

  # "restful all can work"
  block:
    var app = prepareApp()
    app.all("/hi", hello)
    discard testContext(app, "/hi", HttpHead)
    discard testContext(app, "/hi", HttpGet)
    discard testContext(app, "/hi", HttpPost)
    discard testContext(app, "/hi", HttpPut)
    discard testContext(app, "/hi", HttpOptions)
    discard testContext(app, "/hi", HttpDelete)
