import ../../src/prologue


proc home(ctx: Context) {.async.} =
  resp readFile("templates/todoapp.html")


proc staticFileMiddleware*(path: string): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    await switch(ctx)

let settings = newSettings(staticDirs = @["templates"], port = Port(8787))
var app = newApp(settings)
app.addRoute("/home", home)
app.run()
