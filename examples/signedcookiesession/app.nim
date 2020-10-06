import ../../src/prologue
import ../../src/prologue/middlewares/signedcookiesession
import ./urls


let
  env = loadPrologueEnv(".env")
  settings = newSettings(appName = env.getOrDefault("appName", "Prologue"),
                         debug = env.getOrDefault("debug", true),
                         port = Port(env.getOrDefault("port", 8080)),
                         secretKey = env.getOrDefault("secretKey", "")
    )


var app = newApp(settings = settings, middlewares = 
                 @[debugRequestMiddleware(), sessionMiddleware(settings)])
app.addRoute(urls.urlPatterns, "")
app.run()
