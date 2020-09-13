# app.nim
import ../../src/prologue


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"


let settings = newSettings(debug = false)
var app = newApp(settings = settings)
app.addRoute("/hello", hello)
app.run()
