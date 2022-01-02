import ../../../src/prologue

type
  UserContext = ref object of Context
    data: int

# initialize data
method extend(ctx: UserContext) =
  ctx.data = 999

proc hello*(ctx: Context) {.async.} =
  let ctx = UserContext(ctx)
  doAssert ctx.data == 999
  resp "<h1>Hello, Prologue!</h1>"

var app = newApp()
app.get("/", hello)
# app.run(UserContext)