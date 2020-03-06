import ../../src/prologue

import unittest


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc helloName*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.getPathParams("name", "Prologue") & "</h1>"

proc articles*(ctx: Context) {.async.} =
  resp $ctx.getPathParams("num", 1)


suite "Func Test":
  test "serveStaticFile can work":
    let settings = newSettings()
    var app = newApp(settings)
    app.serveStaticFile("templates")
    check app.settings.staticDirs.len == 2
    check app.settings.staticDirs[0] == "static"
    check app.settings.staticDirs[1] == "templates"

  test "serveStaticFiles can work":
    let settings = newSettings()
    var app = newApp(settings)
    app.serveStaticFile(@["templates", "css"])
    check app.settings.staticDirs.len == 3
    check app.settings.staticDirs[0] == "static"
    check app.settings.staticDirs[1] == "templates"
    check app.settings.staticDirs[2] == "css"

  # test "registErrorHandler can work":


  test "addRoute can work":
    let settings = newSettings()
    var app = newApp(settings)
    app.addRoute("/", hello)
    app.addRoute("/hello/{name}", helloName, @[HttpGet, HttpPost])
    app.addRoute(re"/post(?P<num>[\d]+)", articles, HttpGet)
    check app.router.callable[initPath("/", HttpGet)].handler == hello
    check app.router.callable[initPath("/", HttpHead)].handler == hello
    check app.router.callable[initPath("/hello/{name}", HttpPost)].handler == helloName
    check app.reRouter.callable[0][1].handler == articles
