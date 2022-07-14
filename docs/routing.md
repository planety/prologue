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


var app = newApp()
app.addRoute("/hello", hello)
# or
# app.get("/hello", hello)
app.run()
```

You can also use `seq[HttpMethod]` to register the same handler but supports multiple HTTP methods.

```nim
import prologue


# handler
proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

var app = newApp()
app.addRoute("/hello", hello, @[HttpGet, HttpPost])
app.run()
```

## Parameters Routing

`Prologue` supports parameters route. You can use `getPathParams` to get named arguments.


### Basic Example

```nim
import prologue


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.getPathParams("name", "Prologue") & "</h1>"

var app = newApp()
app.addRoute("/hello/{name}", hello, HttpGet)
app.run()
```

### Wildcard

Wildcard will match only one URL section. For examples, `/static/*` only match `/static/static.css`, `/static/etc` and so on. You should use greedy(`$`) character to match multiple URL sections.

```nim
import prologue


proc hello*(ctx: Context) {.async.} =
  resp "Hello, Prologue"

var app = newApp()
app.get("/static/*", hello)
app.get("/*/static", hello)
app.get("/static/templates/{path}/*", hello)
app.run()
```

### Greedy

Greedy character(`$`) will match all the remaining URL sections. But it can only used at the end of the URL. `RouteError` will be raised if it is used in the middle of the URL.

For `/test/{param}$`, `/test/foo/bar/baz/` is matched. The path parameter is "foo/bar/baz". For `/test/*$`, `/test/static/foo/bar/baz/` is matched.

```nim
import prologue


proc hello*(ctx: Context) {.async.} =
  resp "Hello, Prologue"

var app = newApp()
app.get("/test/{param}$", hello)
app.get("/test/static/*$", hello)
app.run()
```


## Regex Routing

`Prologue` supports regex route.

```nim
import prologue


proc articles*(ctx: Context) {.async.} =
  resp $ctx.getPathParams("num", 1)

var app = newApp()
app.addRoute(re"/post(?P<num>[\d]+)", articles, HttpGet)
app.run()
```

## Pattern Routing

```nim
import prologue

proc hello(ctx: Context) {.async.} =
  resp "Hello World!"

const urlPatterns = @[
  pattern("/hello", hello)
]

var app = newApp()

app.addRoute(urlPatterns, "")
app.run()
```

## Group Routing

`Prologue` supports group route. You can add arbitrary levels of route.

```nim
import prologue


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

app.run()
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

app.run()
```

`pattern routing` also supports grouping.

```nim
import prologue


var
  app = newApp()
  base = newGroup(app, "/apiv2", @[])
  level1 = newGroup(app,"/level1", @[], base)
  level2 = newGroup(app, "/level2", @[], level1)


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
app.run()
```

## Tips

You could compile the main program with `-d:logueRouteLoose` to enable loose route matching. Text and wildcard or text and parameters are considered different.
For example `/blog/tag/{slug}` and `/blog/{year}/{id}` are not considered as the duplicated routes. If you define `/blog/tag/{slug}` first, then it will be matched first. Order matters. But `/blog/*/{slug}` and `/blog/{year}/{id}` are still duplicated.
