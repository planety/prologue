import ../../src/prologue

import unittest


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

let settings = newSettings()
var app = newApp(settings)


suite "Func Test":
  test "addRoute can work":
    app.addRoute("/", hello)
    check app.router.callable[initPath("/", HttpGet)].handler == hello
    check app.router.callable[initPath("/", HttpHead)].handler == hello
