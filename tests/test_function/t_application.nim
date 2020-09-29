import ../../src/prologue


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc helloName*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.getPathParams("name", "Prologue") & "</h1>"

proc articles*(ctx: Context) {.async.} =
  resp $ctx.getPathParams("num", 1)

proc go404*(ctx: Context) {.async.} =
  resp "Something wrong!", Http404

proc go20x*(ctx: Context) {.async.} =
  resp "Ok!", Http404

proc go30x*(ctx: Context) {.async.} =
  resp "EveryThing else?", Http404


# "Application Func Test"
block:
  # "registErrorHandler can work"
  block:
    let settings = newSettings()
    var app = newApp(settings)
    app.registerErrorHandler(Http404, go404)
    app.registerErrorHandler({Http200 .. Http204}, go20x)
    app.registerErrorHandler(@[Http301, Http304, Http307], go30x)

    doAssert app.errorHandlerTable[Http404] == go404
    doAssert app.errorHandlerTable[Http202] == go20x
    doAssert app.errorHandlerTable[Http304] == go30x

#   # "addRoute can work"
#   block:
#     let settings = newSettings()
#     var app = newApp(settings)
#     app.addRoute("/", hello)
#     app.addRoute("/hello/{name}", helloName, @[HttpGet, HttpPost])
#     app.addRoute(re"/post(?P<num>[\d]+)", articles, HttpGet)

#     doAssert app.gScope.router[initPath("/", HttpGet)].handler == hello
#     doAssert app.gScope.router[initPath("/", HttpHead)].handler == hello
#     doAssert app.gScope.router[initPath("/hello/{name}", HttpPost)].handler == helloName
#     doAssert app.gScope.reRouter.callable[0][1].handler == articles


# # "Restful Function Test"
# block:
#   # "restful head can work"
#   block:
#     let settings = newSettings()
#     var app = newApp(settings)
#     app.head("/hi", hello)
#     doAssert app.gScope.router[initPath("/hi", HttpHead)].handler == hello

#   # "restful get can work"
#   block:
#     let settings = newSettings()
#     var app = newApp(settings)
#     app.get("/hi", hello)

#     doAssert app.gScope.router[initPath("/hi", HttpGet)].handler == hello
#     doAssert app.gScope.router[initPath("/hi", HttpHead)].handler == hello

#   # "restful post can work"
#   block:
#     let settings = newSettings()
#     var app = newApp(settings)
#     app.post("/hi", hello)
#     doAssert app.gScope.router[initPath("/hi", HttpPost)].handler == hello

#   # "restful put can work"
#   block:
#     let settings = newSettings()
#     var app = newApp(settings)
#     app.put("/hi", hello)
#     doAssert app.gScope.router[initPath("/hi", HttpPut)].handler == hello

#   # "restful delete can work"
#   block:
#     let settings = newSettings()
#     var app = newApp(settings)
#     app.delete("/hi", hello)
#     doAssert app.gScope.router[initPath("/hi", HttpDelete)].handler == hello

#   # "restful trace can work"
#   block:
#     let settings = newSettings()
#     var app = newApp(settings)
#     app.trace("/hi", hello)
#     doAssert app.gScope.router[initPath("/hi", HttpTrace)].handler == hello

#   # "restful options can work"
#   block:
#     let settings = newSettings()
#     var app = newApp(settings)
#     app.options("/hi", hello)
#     doAssert app.gScope.router[initPath("/hi", HttpOptions)].handler == hello

#   # "restful connect can work"
#   block:
#     let settings = newSettings()
#     var app = newApp(settings)
#     app.connect("/hi", hello)
#     doAssert app.gScope.router[initPath("/hi", HttpConnect)].handler == hello

#   # "restful patch can work"
#   block:
#     let settings = newSettings()
#     var app = newApp(settings)
#     app.patch("/hi", hello)
#     doAssert app.gScope.router[initPath("/hi", HttpPatch)].handler == hello

#   # "restful all can work"
#   block:
#     let settings = newSettings()
#     var app = newApp(settings)
#     app.all("/hi", hello)

#     doAssert app.gScope.router[initPath("/hi", HttpGet)].handler == hello
#     doAssert app.gScope.router[initPath("/hi", HttpHead)].handler == hello
#     doAssert app.gScope.router[initPath("/hi", HttpPost)].handler == hello
#     doAssert app.gScope.router[initPath("/hi", HttpPut)].handler == hello
#     doAssert app.gScope.router[initPath("/hi", HttpDelete)].handler == hello
#     doAssert app.gScope.router[initPath("/hi", HttpTrace)].handler == hello
#     doAssert app.gScope.router[initPath("/hi", HttpOptions)].handler == hello
#     doAssert app.gScope.router[initPath("/hi", HttpConnect)].handler == hello
#     doAssert app.gScope.router[initPath("/hi", HttpPatch)].handler == hello
