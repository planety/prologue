import ../../../src/prologue

proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

let app = newApp(settings = newSettings())
app.addRoute("/", hello)
app.run()
