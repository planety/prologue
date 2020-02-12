import prologue, logging


proc hello*(ctx: Context) {.async.} =
  logging.debug "hello"
  resp "<h1>Hello, Prologue!</h1>"

proc home*(ctx: Context) {.async.} =
  logging.debug "home"
  resp "<h1>Home</h1>"

proc helloName*(ctx: Context) {.async.} =
  logging.debug "helloname"
  resp "<h1>Hello, " & getPathParams("name", "Prologue!") & "</h1>"

proc testRedirect*(ctx: Context) {.async.} =
  logging.debug "testRedirect"
  resp redirect("/hello")

proc login*(ctx: Context) {.async.} =
  logging.debug "logging"
  resp loginPage()

proc doLogin*(ctx: Context) {.async.} =
  logging.debug "doLogin"
  resp redirect("/hello/Nim")

let settings = newSettings(appName = "StarLight", debug = true)
var app = initApp(settings = settings, middlewares = @[])
app.addRoute("", home, HttpGet)
app.addRoute("/", home, HttpGet)
app.addRoute("/home", home, HttpGet, @[debugRequestMiddleware()])
app.addRoute("/hello", hello, HttpGet)
app.addRoute("/redirect", testRedirect, HttpGet)
app.addRoute("/login", login, HttpGet)
app.addRoute("/login", doLogin, HttpPost)
app.addRoute("/hello/{name}", helloName, HttpGet)
app.run()
