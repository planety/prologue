import ../../src/prologue
import ../../src/prologue/middlewares/middlewares
from ../../src/prologue/openapi/openapi import serveDocs

import logging

import views, urls

let
  env = loadPrologueEnv(".env")
  settings = newSettings(appName = env.getOrDefault("appName", "Prologue"),
                         debug = env.getOrDefault("debug", true),
                         port = Port(env.getOrDefault("port", 8787)),
                         staticDirs = [env.get("staticDir")],
                         secretKey = env.getOrDefault("secretKey", "")
    )


proc setLoggingLevel() =
  addHandler(newConsoleLogger())
  logging.setLogFilter(lvlInfo)


let 
  event = initEvent(setLoggingLevel)
var
  app = newApp(settings = settings, middlewares = @[debugRequestMiddleware()], startup = @[event])


app.addRoute(urls.urlPatterns, "/todolist")
# only sopport (?P<name>exp)
app.addRoute(re"/post(?P<num>[\d]+)", articles, HttpGet)
app.addRoute(re"/post(?P<name>[\d]+)", articles, HttpGet)

app.addRoute("/", home, HttpGet)
app.addRoute("/", home, HttpPost)
app.addRoute("/index.html", index, HttpGet, name = "index")
app.addRoute("/prefix/home", home, HttpGet)
app.addRoute("/home", home, HttpGet)
app.addRoute("/hello", hello, HttpGet)
app.addRoute("/redirect", testRedirect, HttpGet)
app.addRoute("/login", login, HttpGet)
app.addRoute("/login", do_login, HttpPost)
# will match /hello/Nim and /hello/
app.addRoute("/hello/{name}", helloName, HttpGet, name = "helloname")
app.addRoute("/multipart", multiPart, HttpGet)
app.addRoute("/multipart", do_multiPart, HttpPost)
app.addRoute("/upload", upload, HttpGet)
app.addRoute("/upload", do_upload, HttpPost)
app.serveDocs()
app.run()
