import ../../../src/prologue

proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

let app = newApp()
app.get("/", hello)
app.run()
