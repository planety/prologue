# Context

Context is initialized when a new request enters. You can get the information of the whole Context when you are writing handlers.

You can use attributes of context such as `request`, `response`, `session` and so on.

For example, you can get the HTTP method of the request.

```nim
proc login*(ctx: Context) {.async.} =
  doAssert ctx.request.reqMethod == HttpPost
```

## Context utils

- getPostParams: gets the parameters by HttpPost.
- getQueryParams: gets the query strings(for example, "www.google.com/hello?name=12", `name=12`).
- getPathParams: gets the route parameters(for example, "/hello/{name}").

- setResponse: it is handy to make the response of `ctx`.
- attachment: `attachment` is used to specify the file will be downloaded.
- staticFileResponse: serves static files.

- getUploadFile: gets the `UploadFile` from request.
- save: saves the `UploadFile` to disk.
