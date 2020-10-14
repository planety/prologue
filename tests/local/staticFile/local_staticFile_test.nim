import ../../../src/prologue
import ../../../src/prologue/middlewares

import std/json


proc index(ctx: Context) {.async.} =
  resp "Hello, Nim!"

proc home(ctx: Context) {.async.} =
  await ctx.staticFileResponse("hello.html", "")


let node = %* {
    "prologue": {
        "secretKey": "hello, world",
        "maxBody": 1000
      }
    }

let settings = loadSettings(node)
var app = newApp(settings)
app.addRoute("/", index)
app.addRoute("/home", home, middlewares = @[debugRequestMiddleware(),
    debugResponseMiddleware()])
app.run()
