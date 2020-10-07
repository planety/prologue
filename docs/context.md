# Context

Context is initialized when a new request enters. You can get the information of the whole Context when you are writing handlers.

You can use attributes of context such as `request`, `response`, `session` and so on.

For example, you can get the HTTP method of the request.

```nim
proc login*(ctx: Context) {.async.} =
  doAssert ctx.request.reqMethod == HttpPost
```

## Context utils

### getPostParams

Gets the parameters by HttpPost.

```nim
proc hello(ctx: Context) {.async.} =
  resp ctx.getPostParams("username")
```

### getQueryParams

Gets the query strings(for example, "www.google.com/hello?name=12", `name=12`).

```nim
proc hello(ctx: Context) {.async.} =
  doAssert ctx.getQueryParams("name") == "12"
```

### getPathParams

Gets the route parameters(for example, "/hello/{name}").

```nim
proc hello(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.getPathParams("name", "Prologue") & "</h1>"
```

### getFormParams

Gets the contents of the form if key exists. Otherwise `default` will be returned.
If you need the filename of the form, use `getUploadFile` instead.

```nim
proc hello(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.getFormParams("name", "Prologue") & "</h1>"
```

### setResponse

It is handy to make the response of `ctx`.

```nim
proc hello(ctx: Context) {.async.} =
  ctx.setResponse(Http200, "setResponse")
```

### attachment

`attachment` is used to specify the file will be downloaded.

```nim
proc hello(ctx: Context) {.async.} =
  let downloadName = "test.txt"
  ctx.attachment(downloadName)
```

### staticFileResponse

Returns static files response. The following middlewares processing will be discarded.

```nim
proc hello(ctx: Context) {.async.} =
  await ctx.staticFileResponse("index.html", "static")
```

### getUploadFile
Gets the `UploadFile` from request. `UploadFile` can be saved to disk using `save` function.

```nim
proc upload(ctx: Context) {.async.} =
  if ctx.request.reqMethod == HttpGet:
    await ctx.staticFileResponse("tests/local/uploadFile/upload.html", "")
  elif ctx.request.reqMethod == HttpPost:
    let file = ctx.getUploadFile("file")
    file.save("tests/assets/temp")
    resp fmt"<html><h1>{file.filename}</h1><p>{file.body}</p></html>"
```
