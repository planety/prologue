import prologue

proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc login*(ctx: Context) {.async.} =
  ctx.session["flywind"] = "123"
  ctx.session["ordontfly"] = "345"
  ## Be careful when using session or csrf middlewares,
  ## Response object will cover the headers of before.
  resp htmlResponse("<h1>Login</h1>", headers = ctx.response.headers)

proc print*(ctx: Context) {.async.} =
  resp $ctx.session

proc logout*(ctx: Context) {.async.} =
  ctx.session.clear()
  resp htmlResponse("<h1>Logout</h1>", headers = ctx.response.headers)
