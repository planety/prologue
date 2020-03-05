# Route

Route is the core of web framework.

## Static Route


Register handler `hello` by specifying path, httpMethod and middlewares.

Default http method is `HttpGet`.If you register a handler with `HttpGet`, `Prologue` will automatically register `HttpHead` for this handler.

```nim
# handler
proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

app.addRoute("/hello", hello)
```

You can also use `seq[httpMetod]` to register same handler but support different http methods.

```nim
# handler
proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

app.addRoute("/hello", hello, @[HttpGet, HttpPost])
```

## Parameters Route

`Prologue` support parameters route.

```nim
proc helloName*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.getPathParams("name", "Prologue") & "</h1>"

app.addRoute("/hello/{name}", helloName, HttpGet)
```


```nim
# handler
proc helloName*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.getPathParams("name", "Prologue") & "</h1>"

app.addRoute("/hello/{name}", helloName, HttpGet)
```

