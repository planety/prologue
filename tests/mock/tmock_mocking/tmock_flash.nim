import ../../../src/prologue
import ../../../src/prologue/middlewares/signedcookiesession
import ../../../src/prologue/mocking

import std/[with, uri, strutils]


proc prepareRequest(path: string, httpMethod = HttpGet, cookies = initCookieJar()): Request =
  result = initMockingRequest(
    httpMethod = httpMethod,
    headers = newHttpHeaders(),
    url = parseUri(path),
    cookies = cookies,
    postParams = newStringTable(),
    queryParams = newStringTable(),
    formParams = initFormPart(),
    pathParams = newStringTable()
  )


proc hello(ctx: Context) {.async.} =
  ctx.flash("Please retry again!")
  resp "Hello, world"

proc tea(ctx: Context) {.async.} =
  let msg = ctx.getFlashedMsg(FlashLevel.Info)
  if msg.isSome:
    resp msg.get
  else:
    resp "My tea"

let settings = newSettings()
var app = newApp(settings)

proc getLastSession(ctx: Context): CookieJar =
  result = initCookieJar()
  if ctx.response.hasHeader("Set-Cookie"):
    let value = ctx.response.headers["Set-Cookie", 0]
    result["session"] = value.split(';')[0][8 .. ^1]


with app:
  mockApp()
  use(sessionMiddleware(settings))
  get("/", hello)
  get("/hello", hello)
  get("/tea", tea)

block:
  let ctx1 = app.runOnce(prepareRequest("/"))
  doAssert ctx1.response.body == "Hello, world"

  let ctx2 = app.runOnce(prepareRequest("/tea", cookies = getLastSession(ctx1)))
  doAssert ctx2.response.body == "Please retry again!"

  let ctx3 = app.runOnce(prepareRequest("/tea", cookies = getLastSession(ctx2)))
  doAssert ctx3.response.body == "My tea"

  let ctx4 = app.runOnce(prepareRequest("/tea", cookies = getLastSession(ctx1)))
  doAssert ctx4.response.body == "Please retry again!"
