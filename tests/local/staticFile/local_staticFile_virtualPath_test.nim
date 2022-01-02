import ../../../src/prologue
import ../../../src/prologue/middlewares/staticfilevirtualpath


var app = newApp(newSettings(debug = false))

app.use(staticFileVirtualPathMiddleware("public", "virtual/path/something/public"))
app.run()
