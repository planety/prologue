import ../../src/prologue
import ../../src/prologue/middlewares/signedcookiesession

import urls
import initdb


initDb()


let
  env = loadPrologueEnv(".env")
  secretKey = env.getOrDefault("secretKey", "")
  settings = newSettings(appName = env.getOrDefault("appName", "Prologue"),
      debug = env.getOrDefault("debug", true),
      port = Port(env.getOrDefault("port", 8787)),
      staticDirs = [env.get("staticDir")],
      secretKey = secretKey
  )

var app = newApp(settings = settings, middlewares = @[sessionMiddleware(
    secretKey = secretKey.SecretKey, path = "/")])

app.addRoute(urls.indexPatterns, "/")
app.addRoute(urls.authPatterns, "/auth")
app.addRoute(urls.blogPatterns, "/blog")
app.run()
