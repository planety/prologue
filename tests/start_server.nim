import ../src/prologue except loginPage
import ../src/prologue/middlewares/utils as ut
import ../src/prologue/middlewares/staticfile
import ../src/prologue/middlewares/staticfilevirtualpath
import ../src/prologue/i18n

import std/[with, os, strformat, strutils]

import ./server/utils


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc home*(ctx: Context) {.async.} =
  resp "<h1>Home</h1>"

proc helloName*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.getPathParams("name", "Prologue!") & "</h1>"

proc redirectHome*(ctx: Context) {.async.} =
  resp redirect("/home")

proc loginGet*(ctx: Context) {.async.} =
  resp loginGetPage()

proc doLoginGet*(ctx: Context) {.async.} =
  resp redirect("/hello/Nim")

proc login*(ctx: Context) {.async.} =
  resp loginPage()

proc doLogin*(ctx: Context) {.async.} =
  resp redirect("/hello/Nim")

proc translate*(ctx: Context) {.async.} =
  let zh_CN = ctx.setLanguage("zh_CN")
  doAssert zh_CN.Tr("Hello") == "你好"
  let ja = ctx.setLanguage("ja")
  doAssert ja.Tr("Hello") == "こんにちは"
  doAssert ctx.translate("Hello", "zh_CN") == "你好"
  doAssert ctx.translate("Hello", "ja") == "こんにちは"
  resp "I'm ok."

proc upload(ctx: Context) {.async.} =
  if ctx.request.reqMethod == HttpGet:
    await ctx.staticFileResponse("tests/assets/static/upload.html", "")
  elif ctx.request.reqMethod == HttpPost:
    let 
      file = ctx.getUploadFile("file")
    resp fmt"<html><h1>{file.filename}</h1><p>{file.body}</p></html>"

proc cookie(ctx: Context) {.async.} =
  ctx.setCookie("One", "ok")
  ctx.setCookie("Two", "done")
  resp "Hello"

  doAssert ctx.response.headers["Set-Cookie"] == 
            @["One=ok; SameSite=Lax", "Two=done; SameSite=Lax"]


let settings = newSettings(appName = "Prologue", debug = false, port = Port(8080))
var app = newApp(settings = settings)

with app:
  addRoute("/", home, HttpGet)
  addRoute("/home", home, HttpGet, middlewares = @[debugRequestMiddleware()])
  addRoute("/hello", hello, HttpGet)
  addRoute("/redirect", redirectHome, HttpGet)
  addRoute("/loginget", loginGet, HttpGet)
  addRoute("/loginpage", doLoginGet, @[HttpGet, HttpPost])
  addRoute("/login", login, HttpGet)
  addRoute("/login", doLogin, HttpPost)
  addRoute("/hello/{name}", helloName, HttpGet)
  addRoute("/translate", translate)
  addRoute("/upload", upload, @[HttpGet, HttpPost])
  get("/cookie", cookie)

  get("/favicon.ico", redirectTo("tests/static/favicon.ico"))
  get("/favicon", redirectTo("/tests/static/favicon.ico"))
  loadTranslate(expandFileName("tests/assets/i18n/trans.ini"))
  
  use(
    staticFileVirtualPathMiddleware(
      staticDir = "/tests/static/",
      virtualPath = "/assets/favicons/"
    )
  )
  use(
    staticFileVirtualPathMiddleware(
      staticDir = "/tests/static/",
      virtualPath = "/important/texts/"
    )
  )
  use(
    staticFileVirtualPathMiddleware(
      staticDir = "/tests/static/A/B/C",
      virtualPath = "/very/important/texts/"
    )
  )
  use(
    staticFileVirtualPathMiddleware(
      staticDir = "/tests/static/A/B/C",
      virtualPath = "/important/texts/A"
    )
  )

  run()
