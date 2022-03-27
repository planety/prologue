# Context

Context is initialized when a new request enters. You can get the information of the whole Context when you are writing handlers.

You can use attributes of context such as `request`, `response`, `session` and so on.

For example, you can get the HTTP method of the request.

```nim
proc login*(ctx: Context) {.async.} =
  doAssert ctx.request.reqMethod == HttpPost
```

## Context utils

### getPostParamsOption

Gets the parameters by HttpPost as an `Option[string]`.

Note that: `getPostParamsOption` only handles `form-urlencoded` types.

```nim
proc hello(ctx: Context) {.async.} =
  resp ctx.getPostParamsOption("username").get()
```

If you want to specify a default value to return, take a look at [getPostParams](https://planety.github.io/prologue/coreapi/context.html#getPostParams%2CContext%2Cstring%2Cstring)

### getQueryParamsOption

Gets the query strings(for example, "www.google.com/hello?name=12", `name=12`) as an `Option[string]`.

```nim
proc hello(ctx: Context) {.async.} =
  doAssert ctx.getQueryParamsOption("name").get() == "12"
```

If you want to specify a default value to return, take a look at [getQueryParams](https://planety.github.io/prologue/coreapi/context.html#getQueryParams%2CContext%2Cstring%2Cstring)

### getPathParamsOption

Gets the route parameters(for example, "/hello/{name}") as an `Option[string]`.

```nim
proc hello(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.getPathParamsOption("name").get() & "</h1>"
```

If you want to specify a default value to return and have automatic parsing to int, float or bool (depending on the type of the default you provide), take a look at [getPathParams](https://planety.github.io/prologue/coreapi/context.html#getPathParams%2CContext%2Cstring%2CT)

### getFormParamsOption

Gets the contents of the form if key exists. Otherwise `default` will be returned.
If you need the filename of the form, use `getUploadFile` instead.

Note that: `getFormParams` handles both `form-urlencoded` and `multipart/form-data`.

```nim
proc hello(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.getFormParamsOption("name").get() & "</h1>"
```

If you want to specify a default value to return, take a look at [getFormParams](https://planety.github.io/prologue/coreapi/context.html#getFormParams%2CContext%2Cstring%2Cstring)

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
