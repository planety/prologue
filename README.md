# Prologue
What's past is prologue.

### Purpose
Micro Web framework.

### Usage

#### Hello World

```nim
proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"


let settings = initSettings(appName = "StarLight")
var app = initApp(settings = settings)
app.addRoute("/", hello, HttpGet)
app.addRoute("/hello", hello, HttpGet)
app.run()
```

The server is running at localhost:8080.

#### Another example

```nim
proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc home*(ctx: Context) {.async.} =
  resp "<h1>Home</h1>"

proc helloName*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.request.pathParams.getOrDefault("name", "Prologue") & "</h1>"

proc testRedirect*(ctx: Context) {.async.} =
  resp redirect("/hello")

proc login*(ctx: Context) {.async.} =
  resp loginPage()

proc do_login*(ctx: Context) {.async.} =
  resp redirect("/hello/Nim")

let settings = initSettings(appName = "StarLight")
var app = initApp(settings = settings, middlewares = @[debugRequestMiddleware])
app.addRoute("/", home, HttpGet)
app.addRoute("/", home, HttpPost)
app.addRoute("/home", home, HttpGet)
app.addRoute("/hello", hello, HttpGet)
app.addRoute("/redirect", testRedirect, HttpGet)
app.addRoute("/login", login, HttpGet)
app.addRoute("/login", do_login, HttpPost, @[debugRequestMiddleware])
app.addRoute("/hello/{name}", helloName, HttpGet)
app.run()
```