import ../../../src/prologue
import ../../../src/prologue/middlewares/staticfile


var app = newApp(newSettings(debug = false))

app.use(staticFileMiddleware("public"))
app.run()
