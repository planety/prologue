import ../../../src/prologue
import ../../../src/prologue/middlewares


proc index(ctx: Context) {.async.} =
  resp "Hello, Nim!"

proc home(ctx: Context) {.async.} =
  await ctx.staticFileResponse("hello.html", "", "download.html")


let app = newApp()
app.addRoute("/", index)
app.addRoute("/home", home, middlewares = @[debugRequestMiddleware(),
    debugResponseMiddleware()])
app.run()
