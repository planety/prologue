import ../../src/prologue
import std/asyncdispatch

proc hello*(ctx: Context) {.async.} =
  await sleepAsync(10)
  resp "<h1>Hello after async work!</h1>"

var app = newApp(settings = newSettings(port = Port(9081), debug = false))
app.addRoute("/hello", hello)
app.run()
