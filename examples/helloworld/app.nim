import ../../src/prologue


import controllers, urls

let
  env = loadPrologueEnv(".env")
  settings = newSettings(appName = env.getOrDefault("appName", "Prologue"),
                debug = env.getOrDefault("debug", true),
                port = Port(env.getOrDefault("port", 8080)),
                staticDir = env.get("staticDir"),
                secretKey = SecretKey(env.getOrDefault("secretKey", ""))
    )

var
  app = initApp(settings = settings, middlewares = @[])


app.addRoute(urls.urlPatterns, "/todolist")
# only sopport (?P<name>exp)
app.addRoute(re"/post(?P<num>[\d]+)", articles, HttpGet)

app.addRoute("/", home, HttpGet)
app.addRoute("/", home, HttpPost)
app.addRoute("/docs", docs, HttpGet)
app.addRoute("/redocs", redocs, HttpGet)
app.addRoute("/openapi.json", docsjson, HttpPost)
app.addRoute("/index.html", index, HttpGet)
app.addRoute("/prefix/home", home, HttpGet)
app.addRoute("/home", home, HttpGet)
app.addRoute("/hello", hello, HttpGet)
app.addRoute("/redirect", testRedirect, HttpGet)
app.addRoute("/login", login, HttpGet)
app.addRoute("/login", do_login, HttpPost)
# will match /hello/Nim and /hello/
app.addRoute("/hello/{name}", helloName, HttpGet)
app.addRoute("/multipart", multiPart, HttpGet)
app.addRoute("/multipart", do_multiPart, HttpPost)
app.addRoute("/upload", upload, HttpGet)
app.addRoute("/upload", do_upload, HttpPost)
app.run()
