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
