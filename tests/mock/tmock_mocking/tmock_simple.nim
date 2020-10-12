import ../../../src/prologue
import ../../../src/prologue/mocking

import std/uri


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"


let settings = newSettings(debug = true)
var app = newApp(settings = settings)
app.addRoute("/", hello)
mockApp(app)


let url = parseUri("/")
let req = initMockingRequest(
  httpMethod = HttpGet,
  headers = newHttpHeaders(),
  url = url,
  cookies = initCookieJar(),
  postParams = newStringTable(),
  queryParams = newStringTable(),
  formParams = initFormPart(),
  pathParams = newStringTable()
)
let ctx = runOnce(app, req)
doAssert ctx.response.code == Http200
doAssert ctx.response.getHeader("content-type") == @["text/html; charset=UTF-8"]
doAssert ctx.response.body == "<h1>Hello, Prologue!</h1>"
