import ../src/prologue except loginPage
import ../src/prologue/middlewares/utils as ut
import ../src/prologue/i18n
import logging, os, strformat, strutils

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

proc translate*(ctx: Context) {.async.} =
  let zh_CN = ctx.setLanguage("zh_CN")
  assert zh_CN.Tr("Hello") == "你好"
  let ja = ctx.setLanguage("ja")
  assert ja.Tr("Hello") == "こんにちは"
  assert ctx.translate("Hello", "zh_CN") == "你好"
  assert ctx.translate("Hello", "ja") == "こんにちは"
  resp "I'm ok."

proc upload(ctx: Context) {.async.} =
  if ctx.request.reqMethod == HttpGet:
    await ctx.staticFileResponse("tests/static/upload.html", "")
  elif ctx.request.reqMethod == HttpPost:
    let 
      file = ctx.getUploadFile("file")
    resp fmt"<html><h1>{file.filename}</h1><p>{file.body.strip()}</p></html>"

proc cookie(ctx: Context) {.async.} =
  ctx.setCookie("One", "ok")
  ctx.setCookie("Two", "done")
  resp "Hello"

  doAssert seq[string](ctx.response.headers["Set-Cookie"]) == 
            @["One=ok; SameSite=Lax", "Two=done; SameSite=Lax"]


let settings = newSettings(appName = "StarLight", debug = false, port = Port(8787))
var app = newApp(settings = settings, middlewares = @[])
app.addRoute("", home, HttpGet)
app.addRoute("/", home, HttpGet)
app.addRoute("/home", home, HttpGet, middlewares = @[debugRequestMiddleware()])
app.addRoute("/hello", hello, HttpGet)
app.addRoute("/redirect", redirectHome, HttpGet)
app.addRoute("/loginget", loginGet, HttpGet)
app.addRoute("/loginpage", doLoginGet, @[HttpGet, HttpPost])
app.addRoute("/login", login, HttpGet)
app.addRoute("/login", doLogin, HttpPost)
app.addRoute("/hello/{name}", helloName, HttpGet)
app.addRoute("/translate", translate)
app.addRoute("/upload", upload, @[HttpGet, HttpPost])
app.get("/cookie", cookie)
app.loadTranslate(expandFileName("tests/i18n/trans.ini"))
app.run()
