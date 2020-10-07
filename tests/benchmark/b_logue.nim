# app.nim
import ../../src/prologue

proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

var app = newApp(settings = newSettings(debug = false))
app.addRoute("/hello", hello)
app.run()
