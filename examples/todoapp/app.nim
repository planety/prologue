import ../../src/prologue


proc home(ctx: Context) {.async.} =
  resp redirect("/templates/todoapp.html")


let settings = newSettings(staticDirs = @["templates"])
var app = newApp(settings)
app.addRoute("/home", home)
app.run()
