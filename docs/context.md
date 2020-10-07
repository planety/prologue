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

### getQueryParams
Gets the query strings(for example, "www.google.com/hello?name=12", `name=12`).

### getPathParams

Gets the route parameters(for example, "/hello/{name}").

### setResponse
It is handy to make the response of `ctx`.

### attachment
`attachment` is used to specify the file will be downloaded.

### staticFileResponse
Returns static files response.

### getUploadFile
Gets the `UploadFile` from request. `UploadFile` can be saved to disk using `save` function.
