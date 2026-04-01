import ../../../src/prologue
import ../../../src/prologue/middlewares/cors

proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello with middleware!</h1>"

proc api*(ctx: Context) {.async.} =
  resp jsonResponse(%*{"status": "ok"})

let settings = newSettings(port = Port(9080))
var app = newApp(settings = settings)
app.use(CorsMiddleware(allowOrigins = @["*"]))
app.get("/", hello)
app.get("/api", api)
app.run()
