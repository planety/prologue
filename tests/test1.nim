# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.
import prologue / framework


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc home*(ctx: Context) {.async.} =
  resp "<h1>Home</h1>"

# proc templ*(ctx: Context) {.async.} =
#   resp {"name": "string"}.toTable

proc helloName*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.params.getOrDefault("name", "Prologue") & "</h1>"

proc testRedirect*(ctx: Context) {.async.} =
  await redirect(ctx, "/hello")

let settings = initSettings(appName = "StarLight")
var app = initApp(settings = settings)
app.addRoute("/", home, "", HttpGet)
app.addRoute("/", home, "", HttpPost)
app.addRoute("/home", home, "", HttpGet)
app.addRoute("/hello", hello, "", HttpGet)
app.addRoute("/redirect", testRedirect, "", HttpGet)
# app.addRoute("/hello", hello, "advanced"， HttpGet)
# app.addRoute("/templ", templ, "tempalte", HttpGet)
app.addRoute("/hello/{name}", helloName, "", HttpGet)
app.run()
