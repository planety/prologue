import ../../../src/prologue


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc helloName*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.getPathParams("name", "Prologue") & "</h1>"

proc articles*(ctx: Context) {.async.} =
  resp $ctx.getPathParams("num", 1)

proc go404*(ctx: Context) {.async.} =
  resp "Something wrong!", Http404

proc go20x*(ctx: Context) {.async.} =
  resp "Ok!", Http200

proc go30x*(ctx: Context) {.async.} =
  resp "EveryThing else?", Http301


# "Application Func Test"
block:
  # "registErrorHandler can work"
  block:
    var app = newApp()
    app.registerErrorHandler(Http404, go404)
    app.registerErrorHandler({Http200 .. Http204}, go20x)
    app.registerErrorHandler(@[Http301, Http304, Http307], go30x)

    doAssert app.errorHandlerTable[Http404] == go404
    doAssert app.errorHandlerTable[Http202] == go20x
    doAssert app.errorHandlerTable[Http304] == go30x
