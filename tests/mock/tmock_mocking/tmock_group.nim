import ../../../src/prologue
import ../../../src/prologue/mocking/mocking

import uri


proc prepareRequest(path: string, httpMethod = HttpGet): Request =
  result = initMockingRequest(
    httpMethod = httpMethod,
    headers = newHttpHeaders(),
    url = parseUri(path),
    cookies = initCookieJar(),
    postParams = newStringTable(),
    queryParams = newStringTable(),
    formParams = initFormPart(),
    pathParams = newStringTable()
  )


block:
  var app = newApp(newSettings())
  mockApp(app)

  var base = newGroup(app, "/apiv2", @[])
  var level1 = newGroup(app,"/level1", @[], base)
  var level2 = newGroup(app, "/level2", @[], level1)
  var level3 = newGroup(app, "/level3", @[], level2)


  proc hello(ctx: Context) {.async.} =
    resp "Hello"

  proc hi(ctx: Context) {.async.} =
    resp "Hi"

  proc home(ctx: Context) {.async.} =
    resp "Home"

  base.get("/hello", hello)
  base.get("/hi", hi)
  base.post("/home", home)

  level1.get("/hello", hello)
  level1.get("/hi", hi)
  level1.post("/home", home)

  level2.get("/hello", hello)
  level2.get("/hi", hi)
  level2.post("/home", home)

  level3.get("/hello", hello)
  level3.get("/hi", hi)
  level3.post("/home", home)

  block:
    block:
      let ctx = app.runOnce(prepareRequest("/apiv2/hello"))
      doAssert ctx.response.body == "Hello"

    block:
      let ctx = app.runOnce(prepareRequest("/apiv2/hi"))
      doAssert ctx.response.body == "Hi"

    block:
      let ctx = app.runOnce(prepareRequest("/apiv2/home", HttpPost))
      doAssert ctx.response.body == "Home"

# var tab = {level1: urlpattern1, level3: urlpattern2}
# app.addRoute(tab)
