import ../../src/prologue


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"


let 
  settings = newSettings()
  app = newApp(settings = settings)
app.addRoute("/", hello)
app.run()
