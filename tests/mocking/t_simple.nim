# import ../../src/prologue
# import ../../src/prologue/mocking/mocking

# import uri


# proc hello*(ctx: Context) {.async.} =
#   resp "<h1>Hello, Prologue!</h1>"


# let settings = newSettings(debug = true)
# var app = newApp(settings = settings)
# app.addRoute("/", hello)
# mockApp(app)


# let url = parseUri("/")
# let req = initMockingRequest(
#   httpMethod = HttpGet,
#   headers = newHttpHeaders(),
#   url = url,
#   cookies = initCookieJar(),
#   postParams = newStringTable(),
#   queryParams = newStringTable(),
#   formParams = initFormPart(),
#   pathParams = newStringTable()
# )
# let ctx = runOnce(app, req)
