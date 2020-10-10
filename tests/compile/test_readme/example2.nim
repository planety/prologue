# app.nim
import ../../../src/prologue
import ../../../src/prologue/middlewares


# Async Function
proc home*(ctx: Context) {.async.} =
  resp "<h1>Home</h1>"

proc helloName*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.getPathParams("name", "Prologue") & "</h1>"

proc doRedirect*(ctx: Context) {.async.} =
  resp redirect("/hello")

proc login*(ctx: Context) {.async.} =
  resp loginPage()

proc do_login*(ctx: Context) {.async.} =
  resp redirect("/hello/Nim")


let settings = newSettings(appName = "Prologue", debug = false)
var app = newApp(settings = settings)
app.use(debugRequestMiddleware())
app.addRoute("/", home, @[HttpGet, HttpPost])
app.addRoute("/home", home, HttpGet)
app.addRoute("/redirect", doRedirect, HttpGet)
app.addRoute("/login", login, HttpGet)
app.addRoute("/login", do_login, HttpPost, middlewares = @[debugRequestMiddleware()])
app.addRoute("/hello/{name}", helloName, HttpGet)
app.run()
