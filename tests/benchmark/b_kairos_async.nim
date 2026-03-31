import ../../src/prologue
import chronos

proc hello*(ctx: Context) {.async.} =
  await sleepAsync(10.milliseconds)
  resp "<h1>Hello after async work!</h1>"

var app = newApp(settings = newSettings(port = Port(9080), debug = false))
app.addRoute("/hello", hello)
app.run()
