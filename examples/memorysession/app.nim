import ../../src/prologue
import ../../src/prologue/middlewares/sessions/memorysession
import ./urls

let
  env = loadPrologueEnv(".env")
  secretKey = env.getOrDefault("secretKey", "")
  settings = newSettings(appName = env.getOrDefault("appName", "Prologue"),
                         debug = env.getOrDefault("debug", true),
                         port = Port(env.getOrDefault("port", 8787)),
                         secretKey = secretKey
    )


var app = newApp(settings = settings, middlewares = 
                 @[sessionMiddleware(secretKey = secretKey.SecretKey)])
app.addRoute(urls.urlPatterns, "")
app.run()
