# Routing

Routing is the core of web framework.

## Static Routing

Registering handler `hello` by specifying path, HTTP methods and middlewares.

`HttpGet` is the default HTTP methods. If you have registered a handler with `HttpGet`, `Prologue` will automatically register `HttpHead` for this handler.

```nim
# handler
import prologue


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

app.addRoute("/hello", hello)
# or
# app.get("/hello", hello)
```

You can also use `seq[httpMetod]` to register the same handler but supports multiple HTTP methods.

```nim
import prologue


# handler
proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

app.addRoute("/hello", hello, @[HttpGet, HttpPost])
```

## Parameters Routing

`Prologue` supports parameters route. You can use `getPathParams` to get named arguments.

```nim
import prologue


proc helloName*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.getPathParams("name", "Prologue") & "</h1>"

app.addRoute("/hello/{name}", helloName, HttpGet)
```


### Regex Routing

`Prologue` supports regex route.

```nim
import prologue


proc articles*(ctx: Context) {.async.} =
  resp $ctx.getPathParams("num", 1)

app.addRoute(re"/post(?P<num>[\d]+)", articles, HttpGet)
```

### Pattern Routing

```nim
import prologue

proc hello(ctx: Context) {.async.} =
  resp "Hello World!"

let urlPatterns* = @[
  pattern("/hello", hello)
]

var app = newApp()

app.addRoute(urls.urlPatterns, "")
app.run()
```

### Group Routing

`Prologue` supports group route. You can add arbitrary levels of route.

```nim
import prologue


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

`std/with` provides a more neat routing fashion:

```nim
import prologue
import std/with


var 
  app = newApp()
  base = newGroup(app, "/apiv2", @[])
  level1 = newGroup(app,"/level1", @[], base)
  level2 = newGroup(app, "/level2", @[], level1)
  level3 = newGroup(app, "/level3", @[], level2)


proc hello(ctx: Context) {.async.} =
  resp "Hello"

proc hi(ctx: Context) {.async.} =
  resp "Hi"

proc home(ctx: Context) {.async.} =
  resp "Home"


with base:
  get("/hello", hello)
  get("/hi", hi)
  post("/home", home)

# /apiv2/level1/hello
with level1:
  get("/hello", hello)
  get("/hi", hi)
  post("/home", home)

# /apiv2/level1/level2/hello
with level2:
  get("/hello", hello)
  get("/hi", hi)
  post("/home", home)

# /apiv2/level1/level2/level3/hello
with level3:
  get("/hello", hello)
  get("/hi", hi)
  post("/home", home)
```

`pattern routing` also supports grouping.

```nim
import prologue


var app = newApp()

var base = newGroup(app, "/apiv2", @[])
var level1 = newGroup(app,"/level1", @[], base)
var level2 = newGroup(app, "/level2", @[], level1)


proc hello(ctx: Context) {.async.} =
  resp "Hello"

proc hi(ctx: Context) {.async.} =
  resp "Hi"

proc home(ctx: Context) {.async.} =
  resp "Home"


let
  urlpattern1 = @[pattern("/hello", hello), pattern("/hi", hi)]
  urlpattern2 = @[pattern("/home", home)]
  tab = {level1: urlpattern1, level2: urlpattern2}

app.addGroup(tab)
```
