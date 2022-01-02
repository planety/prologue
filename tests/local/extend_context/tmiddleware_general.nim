import ../../../src/prologue

# middleware for general purpose
type
  ExperimentContext = concept ctx
    ctx is Context
    ctx.data is int

proc init[T: ExperimentContext](ctx: T) =
  ctx.data = 12

proc experimentMiddleware[T: ExperimentContext](ctxType: typedesc[T]): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    let ctx = ctxType(ctx)
    doAssert ctx.data == 12
    inc ctx.data
    await switch(ctx)


type
  UserContext = ref object of Context
    data: int

method extend(ctx: UserContext) =
  init(ctx)

proc hello*(ctx: Context) {.async.} =
  let ctx = UserContext(ctx)
  assert ctx.data == 13
  echo ctx.data
  resp "<h1>Hello, Prologue!</h1>"

var app = newApp()
app.use(experimentMiddleware(UserContext))
app.get("/", hello)
# app.run(UserContext)