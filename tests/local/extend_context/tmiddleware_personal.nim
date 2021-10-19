import ../../../src/prologue

type
  UserContext = ref object of Context
    data: int

proc init(ctx: UserContext) =
  ctx.data = 12

proc experimentMiddleware(): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    let ctx = UserContext(ctx)
    doAssert ctx.data == 12
    inc ctx.data
    await switch(ctx)

method extend(ctx: UserContext) =
  init(ctx)

proc hello*(ctx: Context) {.async.} =
  let ctx = UserContext(ctx)
  assert ctx.data == 13
  echo ctx.data
  resp "<h1>Hello, Prologue!</h1>"

var app = newApp()
app.use(experimentMiddleware())
app.get("/", hello)
# app.run(UserContext)