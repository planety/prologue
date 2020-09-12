import ../../src/prologue

proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc login*(ctx: Context) {.async.} =
  ctx.session["flywind"] = "123"
  resp "<h1>Hello, Prologue!</h1>"

proc logout*(ctx: Context) {.async.} =
  resp $ctx.session
