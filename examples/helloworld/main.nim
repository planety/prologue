import ../../src/prologue


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc home*(ctx: Context) {.async.} =
  echo ctx.request.queryParams.getOrDefault("name", "")
  resp "<h1>Home</h1>"

proc index*(ctx: Context) {.async.} =
  resp htmlResponse("index.html")
# proc templ*(ctx: Context) {.async.} =
#   resp {"name": "string"}.toTable

proc helloName*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.params.getOrDefault("name", "Prologue") & "</h1>"

proc testRedirect*(ctx: Context) {.async.} =
  await ctx.redirect("/hello")

proc login*(ctx: Context) {.async.} =
  resp loginPage()

proc do_login*(ctx: Context) {.async.} =
  await ctx.redirect("/hello/Nim")

let settings = initSettings(appName = "StarLight")
var app = initApp(settings = settings, middlewares = @[debugRequestMiddleware])
app.addRoute("/", home, HttpGet)
app.addRoute("/", home, HttpPost)
app.addRoute("/index.html", index, HttpGet)
app.addRoute("/prefix/home", home, HttpGet)
app.addRoute("/home", home, HttpGet)
app.addRoute("/hello", hello, HttpGet)
app.addRoute("/redirect", testRedirect, HttpGet)
app.addRoute("/login", login, HttpGet)
app.addRoute("/login", do_login, HttpPost, @[debugRequestMiddleware])
# app.addRoute("/hello", hello, HttpGet)
# app.addRoute("/templ", templ, HttpGet)
app.addRoute("/hello/{name}", helloName, HttpGet)
app.run()
