import prologue
import prologue/middlewares/staticfile


proc home(ctx: Context) {.async.} =
  resp readFile("templates/todoapp.html")


var
  app = newApp(newSettings(port = Port(8080)))

app.use(staticFileMiddleware("templates"))
app.addRoute("/home", home)
app.run()
