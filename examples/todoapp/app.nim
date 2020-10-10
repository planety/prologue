import ../../src/prologue
import ../../src/prologue/middlewares/staticfile


proc home(ctx: Context) {.async.} =
  resp readFile("templates/todoapp.html")


let 
  settings = newSettings(port = Port(8080))

var
  app = newApp(settings)

app.use(staticFileMiddleware("templates"))
app.addRoute("/home", home)
app.run()
