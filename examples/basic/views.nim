import prologue
import myctx

proc hello*(ctx: DataContext) {.async.} =
  echo ctx.id
  resp "<h1>Hello, Prologue!</h1>"
