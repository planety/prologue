[![License: BSD-3-Clause](https://img.shields.io/github/license/planety/prologue)](https://opensource.org/licenses/BSD-3-Clause)
[![Version](https://img.shields.io/github/v/release/planety/prologue?include_prereleases)](https://github.com/planety/prologue/releases)


# Prologue
What's past is prologue.

## Purpose
Prologue is a Medium Scale Web Framework which is
ideal for building elegant and high performance
web services.


## Feature

- Configure and Settings
- Context
- Params and Query Data
- Form Data
- Static Files
- Middlewares
- Simple Route
- Regex Route
- CORS Response
- Signing
- Cookie
- Session
- Cache
- Template(Using Karax Native or Using Nim Filter)
- Test Client(Using httpclient)

## Installation

```bash
nimble install prologue
```

## Usage

### Hello World

```nim
proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"


let settings = newSettings()
var app = initApp(settings = settings)
app.addRoute("/", hello)
app.run()
```

The server is running at localhost:8080.

### Another Example

```nim
# Async Function
proc home*(ctx: Context) {.async.} =
  resp "<h1>Home</h1>"

proc helloName*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & getPathParams("name", "Prologue") & "</h1>"

proc login*(ctx: Context) {.async.} =
  resp loginPage()

proc do_login*(ctx: Context) {.async.} =
  resp redirect("/hello/Nim")


let settings = newSettings(appName = "StarLight")
var app = initApp(settings = settings, middlewares = @[debugRequestMiddleware])
app.addRoute("/", home, @[HttpGet, HttpPost])
app.addRoute("/home", home, HttpGet)
app.addRoute("/redirect", testRedirect, HttpGet)
app.addRoute("/login", login, HttpGet)
app.addRoute("/login", do_login, HttpPost, @[debugRequestMiddleware])
app.addRoute("/hello/{name}", helloName, HttpGet)
app.run()
```

### Urls Files
**views.nim**

```nim
import prologue


proc index*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc hello*(ctx: Context) {.async.} =
  echo ctx.request.queryParams.getOrDefault("name", "")
  resp "<h1>Home</h1>"
```

**urls.nim**

```nim

import prologue


import views


let urlPatterns* = @[
  pattern("/", index),
  pattern("/", index, HttpPost),
  pattern("/hello/{name}", hello),
]
```

**app.nim**

```nim
import prologue


import views, urls

# read environment variables from file
# Make sure ".env" in your ".gitignore" file.
let 
  env = loadPrologueEnv(".env")

let
  settings = newSettings(appName = env.getOrDefault("appName", "Prologue"),
                debug = env.getOrDefault("debug", true), 
                port = Port(env.getOrDefault("port", 8080)),
                staticDir = env.get("staticDir"),
                secretKey = SecretKey(env.getOrDefault("secretKey", ""))
                )

var app = initApp(settings = settings, middlewares = @[])
app.addRoute(urls.urlPatterns, "/api")
app.addRoute("/", index, HttpGet)
app.run()
```

### More Examples
- [HelloWorld](https://github.com/planety/prologue/tree/master/examples/helloworld)
- [ToDoList](https://github.com/planety/prologue/tree/master/examples/todolist)
