# app.nim
import ../../src/prologue
import ../../src/prologue/middlewares/middlewares
import ../../src/prologue/dsl/route_dsl


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


let settings = newSettings(appName = "StarLight")
var app = newApp(settings = settings, middlewares = @[debugRequestMiddleware()])

app.route:
  get post "/" home
  get post "/home" home
  get "/redirect" doRedirect
  get "/login" login  
  post "/login" login debugRequestMiddleware()
  get "/hello/{name}" helloName
app.run()
