# Request

`Request` contains the information from the HTTP server. You can visit this attribute by using `ctx.request`.

For example If you want to get state from users, query the `cookies` attribute.

```nim
proc hello(ctx: Context) {.async.} =
  if ctx.request.cookies.hasKey("happy"):
    echo "Yea, I'm happy"
```


## Request utils

### request.url
Gets the url of the request.

```nim
proc hello(ctx: Context) {.async.} =
  echo ctx.request.url
```

### request.port 
Gets the port of the request.

```nim
proc hello(ctx: Context) {.async.} =
  echo ctx.request.port.int
```

### request.path
Gets the path of the request.

```nim
proc hello(ctx: Context) {.async.} =
  echo ctx.request.path
```


### request.reqMethod
Gets the `HttpMethod` of the request.

```nim
proc hello(ctx: Context) {.async.} =
  echo ctx.request.reqMethod
```

### request.contentType
Gets the contentType of the request.

```nim
proc hello(ctx: Context) {.async.} =
  echo ctx.request.contentType
```

### request.hostName
Gets the hostname of the request.

```nim
proc hello(ctx: Context) {.async.} =
  echo ctx.request.hostName
```
