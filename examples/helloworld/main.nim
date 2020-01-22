import ../../src/prologue


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc home*(ctx: Context) {.async.} =
  resp "<h1>Home</h1>"

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
var app = initApp(settings = settings)
app.addRoute("/", home, "", HttpGet)
app.addRoute("/", home, "", HttpPost)
app.addRoute("/home", home, "", HttpGet)
app.addRoute("/hello", hello, "", HttpGet)
app.addRoute("/redirect", testRedirect, "", HttpGet)
app.addRoute("/login", login, "", HttpGet, @[debugRequestMiddleware])
app.addRoute("/login", do_login, "", HttpPost, @[debugRequestMiddleware])
# app.addRoute("/hello", hello, "advanced"， HttpGet)
# app.addRoute("/templ", templ, "tempalte", HttpGet)
app.addRoute("/hello/{name}", helloName, "", HttpGet)
app.run()
