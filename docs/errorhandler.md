# Error Handler

## User-defined error pages

When web application encounters some unexpected situations, it may send 404 response to the client.
You may want to use user-defined 404 pages, then you can use `resp` to return 404 response.


```nim
proc hello(ctx: Context) {.async.} =
  resp "Something is wrong, please retry.", Http404
```

`Prologue` also provides an `error404` helper function to create a 404 response.

```nim
proc hello(ctx: Context) {.async.} =
  resp error404(headers = ctx.response.headers)
```

Or use `errorPage` to create a more descriptive error page.

```nim
proc hello(ctx: Context) {.async.} =
  resp errorPage("Something is wrong"), Http404
```

## Default error handler

Users can also set the default error handler. When `ctx.response.body` is empty, web application will use the default error handler.

The basic example with `respDefault` which is equal to `resp errorPage("Something is wrong"), Http404`.

```nim
proc hello(ctx: Context) {.async.} =
  respDefault Http404
```

`Prologue` has registered two error handlers before application starts, namely `default404Handler` for `Http404` and `default500Handler` for `Http500`. You can change them using `registerErrorHandler`.

```nim
proc go404*(ctx: Context) {.async.} =
  resp "Something wrong!", Http404

proc go20x*(ctx: Context) {.async.} =
  resp "Ok!", Http200

proc go30x*(ctx: Context) {.async.} =
  resp "EveryThing else?", Http301

app.registerErrorHandler(Http404, go404)
app.registerErrorHandler({Http200 .. Http204}, go20x)
app.registerErrorHandler(@[Http301, Http304, Http307], go30x)
```

If you don't want to use the default Error handler, you could clear the whole error handler table.

```nim
var app = newApp(errorHandlerTable = newErrorHandlerTable())
```

## HTTP 500 handler

`Http 500` indicates the internal error of the framework. In debug mode(`settings.debug = true`), the framework will send the exception msgs to the web browser if the length of error msgs is greater than zero. 
Otherwise, the framework will use the default error handled which has been registered before the application starts. Users could cover this handler by using their own error handler.