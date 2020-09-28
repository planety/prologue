# import  httpcore
# import ../../src/prologue/core/route

# import strtabs



#   route: string,
#   httpMethod: HttpMethod,
#   handler: HandlerAsync,
#   middlewares: seq[HandlerAsync],
#   settings: Settings
# ) =

# let middlewares: seq[HandlerAsync] = @[]
# let settings: Settings = nil

# proc testHandler(ctx: Context) {.async.} =
#   echo "test"


# block Basic_Mapping:

#   #test "Root":
#   block:
#     let r = newRouter()
#     r.addRoute("/", HttpGet, testHandler, middlewares, settings)

    
#     r.map(testHandler, HttpGet, "/")
#     let result = r.route("GET", "/")
#     doAssert(result.handler == testHandler)

#   # test "Multiple mappings with a root":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/")
#     r.map(testHandler, $HttpGet, "/foo/bar")
#     r.map(testHandler, $HttpGet, "/baz")
#     let result1 = r.route("GET", "/")
#     doAssert(result1.handler == testHandler)
#     let result2 = r.route("GET", "/foo/bar")
#     doAssert(result2.handler == testHandler)
#     let result3 = r.route("GET", "/baz")
#     doAssert(result3.handler == testHandler)

#   # test "Multiple mappings without a root":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/foo/bar")
#     r.map(testHandler, $HttpGet, "/baz")
#     let result1 = r.route("GET", "/foo/bar")
#     doAssert(result1.handler == testHandler)
#     let result2 = r.route("GET", "/baz")
#     doAssert(result2.handler == testHandler)

#   # test "Duplicate root":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/")
#     let result = r.route("GET", "/")
#     doAssert(result.handler == testHandler)
#     doAssertRaises(MappingError):
#       r.map(testHandler, $HttpGet, "/")

#   # test "Ends with wildcard":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/*")
#     let result = r.route("GET", "/wildcard1")
#     doAssert(result.status == routingSuccess)
#     doAssert(result.handler == testHandler)

#   # test "Ends with param":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/{param1}")
#     let result = r.route("GET", "/value1")
#     doAssert(result.status == routingSuccess)
#     doAssert(result.handler == testHandler)
#     doAssert(result.arguments.pathArgs.getOrDefault("param1") == "value1")

#   # test "Wildcard in middle":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/*/test")
#     let result = r.route("GET", "/wildcard1/test")
#     doAssert(result.status == routingSuccess)
#     doAssert(result.handler == testHandler)

#   # test "Param in middle":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/{param1}/test")
#     let result = r.route("GET", "/value1/test")
#     doAssert(result.status == routingSuccess)
#     doAssert(result.handler == testHandler)
#     doAssert(result.arguments.pathArgs.getOrDefault("param1") == "value1")

#   # test "Param + wildcard":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/{param1}/*")
#     let result = r.route("GET", "/value1/test")
#     doAssert(result.status == routingSuccess)
#     doAssert(result.handler == testHandler)
#     doAssert(result.arguments.pathArgs.getOrDefault("param1") == "value1")

#   # test "Wildcard + param":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/*/{param1}")
#     let result = r.route("GET", "/somevalue/value1")
#     doAssert(result.status == routingSuccess)
#     doAssert(result.handler == testHandler)
#     doAssert(result.arguments.pathArgs.getOrDefault("param1") == "value1")

#   # test "Trailing slash has no effect":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/some/url/")
#     let result1 = r.route("GET", "/some/url")
#     doAssert(result1.status == routingSuccess)
#     let result2 = r.route("GET", "/some/url/")
#     doAssert(result2.status == routingSuccess)

#   # test "Trailing slash doesn't make a unique mapping":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/some/url/")
#     doAssertRaises(MappingError):
#       r.map(testHandler, $HttpGet, "/some/url")

#   # test "Varying param names don't make a unique mapping":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/has/{paramA}")
#     doAssertRaises(MappingError):
#       r.map(testHandler, $HttpGet, "/has/{paramB}")

#   # test "Param vs wildcard don't make a unique mapping":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/has/{param}")
#     doAssertRaises(MappingError):
#       r.map(testHandler, $HttpGet, "/has/*")

#   # test "Greedy params must go at the end of a mapping":
#   block:
#     let r = newRouter[proc()]()
#     doAssertRaises(MappingError):
#       r.map(testHandler, $HttpGet, "/has/{p1}$/{p2}")

#   # test "Greedy wildcards must go at the end of a mapping":
#   block:
#     let r = newRouter[proc()]()
#     doAssertRaises(MappingError):
#       r.map(testHandler, $HttpGet, "/has/*$/*")

#   # test "Wildcards only match one URL section":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/has/*/one")
#     let result = r.route("GET", "/has/a/b/one")
#     doAssert(result.status == routingFailure)

#   # test "Invalid characters in URL":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/test/{param}")
#     let result = r.route("GET", "/test/!/")
#     doAssert(result.status == routingFailure)

#   # test "Remaining path consumption with parameter":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/test/{param}$")
#     let result = r.route("GET", "/test/foo/bar/baz")
#     doAssert(result.status == routingSuccess)

#   # test "Remaining path consumption with wildcard":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/test/*$")
#     let result = r.route("GET", "/test/foo/bar/baz")
#     doAssert(result.status == routingSuccess)

#   # test "Map subpath after path":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/hello")
#     r.map(testHandler, $HttpGet, "/") # Should not raise



# block Parameter_Capture:
#   proc testHandler() = echo "test"

#   # test "Path param that consumes entire path":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/{pathParam1}$")
#     let result = r.route("GET", "/foo/bar/baz")
#     doAssert(result.status == routingSuccess)

#   # test "Path param combined with consuming path param":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/{pathParam1}/{pathParam2}$")
#     let result = r.route("GET", "/foo/bar/baz")
#     doAssert(result.status == routingSuccess)

#   # test "Path param combined with consuming wildcard":
#   block:
#     let r = newRouter[proc()]()
#     r.map(testHandler, $HttpGet, "/{pathParam1}/*$")
#     let result = r.route("GET", "/foo/bar/baz")
#     doAssert(result.status == routingSuccess)
