# Request

`Request` contains the information from the HTTP server. You can visit this attribute by using `ctx.request`.

for example, you maybe want to get state from users, you can query the `cookies` attribute.

```nim
proc hello(ctx: Context) {.async.} =
  if ctx.request.cookies.hasKey("happy"):
    echo "Yea, I'm happy"
```


## Request utils
- request.url: gets the url of the request
- request.port: gets the port of the request
- request.path: gets the path of the request.
- request.reqMethod: gets the `HttpMethod` of the request.
- request.contentType: gets the contentType of the request.
- request.hostName: gets the hostname of the request.
