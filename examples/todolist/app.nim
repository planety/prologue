import ../../src/prologue


import urls

let
  env = loadPrologueEnv(".env")
  settings = newSettings(appName = env.getOrDefault("appName", "Prologue"),
                debug = env.getOrDefault("debug", true),
                port = Port(env.getOrDefault("port", 8080)),
                staticDir = env.get("staticDir"),
                secretKey = SecretKey(env.getOrDefault("secretKey", ""))
    )

var
  app = initApp(settings = settings, middlewares = @[debugRequestMiddleware()])


app.addRoute(urls.urlPatterns, "")
app.generateDocs()
app.run()
