import ../../src/prologue

import unittest


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc helloName*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.getPathParams("name", "Prologue") & "</h1>"

proc articles*(ctx: Context) {.async.} =
  resp $ctx.getPathParams("num", 1)


let settings = newSettings()
var app = newApp(settings)


suite "Func Test":
  test "can add all route":
    app.addRoute("/", hello)
    app.addRoute("/hello/{name}", helloName, @[HttpGet, HttpPost])
    app.addRoute(re"/post(?P<num>[\d]+)", articles, HttpGet)

  test "addRoute static route can work":
    check app.router.callable[initPath("/", HttpGet)].handler == hello
    check app.router.callable[initPath("/", HttpHead)].handler == hello

  test "addRoute parameters route can work":
    check app.router.callable[initPath("/hello/{name}", HttpPost)].handler == helloName
    
  test "addRoute regex route can work":
    check app.reRouter.callable[0][1].handler == articles
