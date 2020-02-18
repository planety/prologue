![Build Status](https://github.com/planety/prologue/workflows/Test%20Prologue/badge.svg)
[![Build Status](https://dev.azure.com/xzsflywind/xlsx/_apis/build/status/planety.prologue?branchName=master)](https://dev.azure.com/xzsflywind/xlsx/_build/latest?definitionId=4&branchName=master)
![Build Status](https://travis-ci.org/planety/prologue.svg?branch=master)

[![License: BSD-3-Clause](https://img.shields.io/github/license/planety/prologue)](https://opensource.org/licenses/BSD-3-Clause)
[![Version](https://img.shields.io/github/v/release/planety/prologue?include_prereleases)](https://github.com/planety/prologue/releases)


# Prologue

What's past is prologue.

## Purpose
Prologue is a Medium Scale Web Framework which is
ideal for building elegant and high performance
web services.


## Documentation

You can read documentation in https://planety.github.io/prologue


## Feature

- Server
  - [ ] High Performance Http 1.1/2.0 Server
  - [ ] High Performance Websocket Server
  - [ ] Http 2.0 Client
  - [ ] SSL/HttpS Support
  - [ ] Reloader
- Core
  - [x] Configure and Settings
  - [x] Context
  - [x] Params and Query Data
  - [x] Form Data
  - [x] Static Files
  - [x] Middlewares
  - [x] Simple Route
  - [x] Regex Route
  - [x] CORS Response
  - [x] Signing
  - [x] Cookie
  - [x] Session
  - [x] Cache
  - [ ] Startup and Shutdown Events
  - [ ] Cross-Site Request Forgery
  - [ ] Cross-Site Scripting (XSS) Protection
  - [ ] Clickjacking Protection
  - [ ] Host header validation
  - [ ] Referrer policy
  - [ ] Live Monitor
  - [ ] Flashing Messages
  - [ ] Authentication
- Plugin
  - [x] Template(Using Karax Native or Using Nim Filter)
  - [x] Test Client(Using httpclient)
  - [ ] Openapi

## Installation

```bash
nimble install prologue
```

## Usage


### Hello World

```nim
proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"


let settings = newSettings(appName = "StarLight", debug = true)
var app = initApp(settings = settings, middlewares = @[stripPathMiddleware()])
app.addRoute("/", hello, HttpGet)
app.addRoute("/hello", hello, HttpGet)
app.run()
```

The server is running at localhost:8080.

### Another example

```nim
# Async Function
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


let settings = newSettings(appName = "StarLight")
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

The server is running at localhost:8080.

### More examples
- [HelloWorld](https://github.com/planety/prologue/tree/master/examples/helloworld)
- [ToDoList](https://github.com/planety/prologue/tree/master/examples/todolist)
