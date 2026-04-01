import ../../../src/prologue

proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue on Kairos!</h1>"

let settings = newSettings(port = Port(9080))
var app = newApp(settings = settings)
app.get("/", hello)
app.run()
