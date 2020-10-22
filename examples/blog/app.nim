import prologue
import prologue/middlewares/signedcookiesession
import prologue/middlewares/staticfile

import ./urls
import ./initdb


initDb()

let
  env = loadPrologueEnv(".env")
  settings = newSettings(appName = env.getOrDefault("appName", "Prologue"),
      debug = env.getOrDefault("debug", true),
      port = Port(env.getOrDefault("port", 8080)),
      secretKey = env.getOrDefault("secretKey", "")
  )

var app = newApp(settings = settings)

app.use(staticFileMiddleware(env.get("staticDir")), sessionMiddleware(settings, path = "/"))
app.addRoute(urls.indexPatterns, "/")
app.addRoute(urls.authPatterns, "/auth")
app.addRoute(urls.blogPatterns, "/blog")
app.run()
