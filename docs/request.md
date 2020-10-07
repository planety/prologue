# Request

`Request` contains the information from the HTTP server. You can visit this attribute by using `ctx.request`.

for example, you maybe want to get state from users, you can query the `cookies` attribute.

```nim
proc hello(ctx: Context) {.async.} =
  if ctx.request.cookies.hasKey("happy"):
    echo "Yea, I'm happy"
```


## Request utils

### request.url
Gets the url of the request.

### request.port 
Gets the port of the request.

### request.path
Gets the path of the request.

### request.reqMethod
Gets the `HttpMethod` of the request.

### request.contentType
Gets the contentType of the request.

### request.hostName
Gets the hostname of the request.
