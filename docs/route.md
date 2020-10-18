# Route

Route is the core of web framework.

## Static Route

Registering handler `hello` by specifying path, HTTP methods and middlewares.

`HttpGet` is the default HTTP methods. If you have registered a handler with `HttpGet`, `Prologue` will automatically register `HttpHead` for this handler.

```nim
# handler
proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

app.addRoute("/hello", hello)
```

You can also use `seq[httpMetod]` to register the same handler but supports multiple HTTP methods.

```nim
# handler
proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

app.addRoute("/hello", hello, @[HttpGet, HttpPost])
```

## Parameters Route

`Prologue` supports parameters route. You can use `getPathParams` to get named arguments.

```nim
proc helloName*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.getPathParams("name", "Prologue") & "</h1>"

app.addRoute("/hello/{name}", helloName, HttpGet)
```


### Regex Route

`Prologue` supports regex route.

```nim
proc articles*(ctx: Context) {.async.} =
  resp $ctx.getPathParams("num", 1)

app.addRoute(re"/post(?P<num>[\d]+)", articles, HttpGet)
```

### Group Route

`Prologue` supports group route. You can add arbitrary levels of route.

```nim
var app = newApp()
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

# /apiv2/hello
base.get("/hello", hello)
base.get("/hi", hi)
base.post("/home", home)

# Or
# import std/with
# with base:
#   get("/hello", hello)
#   get("/hi", hi)
#   post("/home", home)

# /apiv2/level1/hello
level1.get("/hello", hello)
level1.get("/hi", hi)
level1.post("/home", home)

# /apiv2/level1/level2/hello
level2.get("/hello", hello)
level2.get("/hi", hi)
level2.post("/home", home)

# /apiv2/level1/level2/level3/hello
level3.get("/hello", hello)
level3.get("/hi", hi)
level3.post("/home", home)
```
