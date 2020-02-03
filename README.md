![Test Prologue](https://github.com/planety/prologue/workflows/Test%20Prologue/badge.svg)

# Prologue
What's past is prologue.

### Purpose
It tends to be Micro Web Framework and will be one part of our Full-Stack Web Framework, namely Starlight.

You can see our task assignment as below or join us.

https://github.com/planety/BluePrint/blob/master/task.md


### Usage

#### Hello World

```nim
proc hello*(ctx: Context) =
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
# Sync Function
proc hello*(ctx: Context) =
  resp "<h1>Hello, Prologue!</h1>"

proc home*(ctx: Context) =
  resp "<h1>Home</h1>"

# Async Function
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

#### Urls Files
**views.nim**

```nim
import prologue


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc home*(ctx: Context) {.async.} =
  echo ctx.request.queryParams.getOrDefault("name", "")
  resp "<h1>Home</h1>"

proc index*(ctx: Context) {.async.} =
  resp htmlResponse("index.html")

proc helloName*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.request.pathParams.getOrDefault("name", "Prologue") & "</h1>"

proc testRedirect*(ctx: Context) {.async.} =
  resp redirect("/hello")

proc login*(ctx: Context) {.async.} =
  resp loginPage()

proc do_login*(ctx: Context) {.async.} =
  echo "-----------------------------------------------------"
  echo ctx.request.postParams
  echo ctx.request.postParams.getOrDefault("username", "")
  echo ctx.request.postParams.getOrDefault("password", "")
  resp redirect("/hello/Nim")

proc multiPart*(ctx: Context) {.async.} =
  resp multiPartPage()

proc do_multiPart*(ctx: Context) {.async.} = 
  echo "do_multiPart"
  resp redirect("/login")
```

**urls.nim**

```nim

import prologue


import views


let urlPatterns* = @[
  pattern("/", home),
  pattern("/", home, HttpPost),
  pattern("/home", home),
  pattern("/login", login),
  pattern("/login", do_login, HttpPost),
  pattern("/redirect", testRedirect),
  pattern("/multipart", multipart)
]
```

**app.nim**

```nim
import prologue


import views, urls

let settings = newSettings(appName = "StarLight")
var app = initApp(settings = settings, middlewares = @[])
app.addRoute(urls.urlPatterns, "/todolist")
app.addRoute("/", home, HttpGet)
app.addRoute("/", home, HttpPost)
app.addRoute("/index.html", index, HttpGet)
app.addRoute("/prefix/home", home, HttpGet)
app.addRoute("/home", home, HttpGet)
app.addRoute("/hello", hello, HttpGet)
app.addRoute("/redirect", testRedirect, HttpGet)
app.addRoute("/login", login, HttpGet)
app.addRoute("/login", do_login, HttpPost)
app.addRoute("/hello/{name}", helloName, HttpGet)
app.addRoute("/multipart", multiPart, HttpGet)
app.addRoute("/multipart", do_multiPart, HttpPost)
app.run()
```
