import ../../src/prologue

proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc login*(ctx: Context) {.async.} =
  ctx.session["flywind"] = "123"
  ctx.session["ordontfly"] = "345"
  resp redirect("/print", Http302)

proc print*(ctx: Context) {.async.} =
  resp $ctx.session

proc logout*(ctx: Context) {.async.} =
  ctx.session.clear()
  resp redirect("/print", Http302)
