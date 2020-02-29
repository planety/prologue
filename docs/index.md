[![License: BSD-3-Clause](https://img.shields.io/github/license/planety/prologue)](https://opensource.org/licenses/BSD-3-Clause)
[![Version](https://img.shields.io/github/v/release/planety/prologue?include_prereleases)](https://github.com/planety/prologue/releases)


# Prologue
What's past is prologue.

## Purpose
`Prologue` is a Full-Stack Web Framework which is
ideal for building elegant and high performance
web services.


## Feature

- Configure and Settings
- Context
- Param and Query Data
- Form Data
- Static Files
- Middleware
- Startup and Shutdown Events
- Simple Route
- Regex Route
- CORS Response
- Cross-Site Request Forgery
- Exception Handler
- Signing
- Cookie
- Session
- Cache
- URL Building
- Template(Using Karax Native or Using Nim Filter)
- Test Client(Using httpclient)

## Installation
First you should install [Nim](https://nim-lang.org/) language which is an elegant and high performance language.Follow the [instructions](https://nim-lang.org/install.html) and set environment variables correctly.

Then you can use `nimble` command to install prologue.

```bash
nimble install prologue@#head
```

## Usage

### Hello World

```nim
# app.nim
import prologue


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"


let settings = newSettings()
var app = newApp(settings = settings)
app.addRoute("/", hello)
app.run()
```

Run **app.nim**.Now the server is running at localhost:8080.

### Another Example

```nim
# app.nim
import prologue


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
var app = newApp(settings = settings, middlewares = @[debugRequestMiddleware])
app.addRoute("/", home, @[HttpGet, HttpPost])
app.addRoute("/home", home, HttpGet)
app.addRoute("/redirect", testRedirect, HttpGet)
app.addRoute("/login", login, HttpGet)
app.addRoute("/login", do_login, HttpPost, @[debugRequestMiddleware])
app.addRoute("/hello/{name}", helloName, HttpGet)
app.run()
```

Run **app.nim**.Now the server is running at localhost:8080.

### URLs Files
**views.nim**

```nim
import prologue


proc index*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc hello*(ctx: Context) {.async.} =
  echo ctx.request.queryParams.getOrDefault("name", "")
  resp "<h1>Home</h1>"
```

**URLs.nim**

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
  settings = newSettings(appName = env.getOrDefault("appName", "Prologue"),
                debug = env.getOrDefault("debug", true), 
                port = Port(env.getOrDefault("port", 8080)),
                staticDir = env.get("staticDir"),
                secretKey = SecretKey(env.getOrDefault("secretKey", ""))
                )

var app = newApp(settings = settings, middlewares = @[])
app.addRoute(urls.urlPatterns, "/api")
app.addRoute("/", index, HttpGet)
app.run()
```

Run **app.nim**.Now the server is running at localhost:8080.

### More Examples
- [HelloWorld](https://github.com/planety/prologue/tree/master/examples/helloworld)
- [ToDoList](https://github.com/planety/prologue/tree/master/examples/todolist)
