import prologue
import myctx

proc hello*(ctx: Context) {.async.} =
  let ctx = DataContext(ctx)
  echo ctx.id
  resp "<h1>Hello, Prologue!</h1>"
