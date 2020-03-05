import ../src/prologue except loginPage
import logging

import test_core/utils


proc hello*(ctx: Context) {.async.} =
  logging.debug "hello"
  resp "<h1>Hello, Prologue!</h1>"

proc home*(ctx: Context) {.async.} =
  logging.debug "home"
  resp "<h1>Home</h1>"

proc helloName*(ctx: Context) {.async.} =
  logging.debug "helloname"
  resp "<h1>Hello, " & ctx.getPathParams("name", "Prologue!") & "</h1>"

proc redirectHome*(ctx: Context) {.async.} =
  logging.debug "redirectHome"
  resp redirect("/home")

proc loginGet*(ctx: Context) {.async.} =
  logging.debug "login get"
  resp loginGetPage()

proc doLoginGet*(ctx: Context) {.async.} =
  logging.debug "doLogin get"
  resp redirect("/hello/Nim")
  
proc login*(ctx: Context) {.async.} =
  logging.debug "log post"
  resp loginPage()

proc doLogin*(ctx: Context) {.async.} =
  logging.debug "doLogin post"
  resp redirect("/hello/Nim")


let settings = newSettings(appName = "StarLight", debug = true)
var app = newApp(settings = settings, middlewares = @[])
app.addRoute("", home, HttpGet)
app.addRoute("/", home, HttpGet)
app.addRoute("/home", home, HttpGet, @[debugRequestMiddleware()])
app.addRoute("/hello", hello, HttpGet)
app.addRoute("/redirect", redirectHome, HttpGet)
app.addRoute("/loginget", loginGet, HttpGet)
app.addRoute("/loginpage", doLoginGet, HttpGet)
app.addRoute("/login", login, HttpGet)
app.addRoute("/login", doLogin, HttpPost)
app.addRoute("/hello/{name}", helloName, HttpGet)
app.run()
