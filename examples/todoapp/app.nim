import ../../src/prologue
import ../../src/prologue/middlewares/middlewares


proc home(ctx: Context) {.async.} =
  resp readFile("templates/todoapp.html")


proc staticFileMiddleware*(path: string): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    await switch(ctx)

let settings = newSettings(staticDirs = @["templates"])
var app = newApp(settings)
app.addRoute("/home", home)
app.run()
