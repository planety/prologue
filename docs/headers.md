# Headers

Prologue provides two types of `headers`. One is the headers of `request` which carries information from the client. The other is the headers of `response` which carries information sent to the client.


## The headers of the request

The client will send headers to our HTTP server. You may want to check whether some keys are in the headers. 
If existing, you could get the values of them. The return type of `ctx.request.getHeader` is `seq[string]`. You often only need the first element of the sequence.

The following code first checks whether the key exists in headers. If true, retrieve the sequence of values and display them in the browser.

```nim
proc hello(ctx: Context) {.async.} =
  if ctx.request.hasHeader("cookie"):
    let values = ctx.request.getHeader("cookie")
    resp $values
  elif ctx.request.hasHeader("content-type"):
    let values = ctx.request.getHeaderOrDefault("content")
    resp $values
```

## The headers of the response

`Prologue` also sends HTTP headers to the client. It uses `ResponseHeaders` to store them. It has similar API like the headers of the request. First, `Prologue` initializes `ctx.response` with `initResponseHeaders`. Then 
users could use `hasHeader`, `addHeader` or `setHeader` to do what they want. 

Notes that, `addHeader` will append values to existing keys in headers. `setHeader` will reset the values of key no matter whether key is in the headers. 

```nim
proc hello(ctx: Context) {.async.} =
  ctx.response.addHeader("Content-Type", "text/plain")

  doAssert ctx.response.getHeader("CONTENT-TYPE") == @[
        "text/html; charset=UTF-8", "text/plain"]

  ctx.response.setHeader("Content-Type", "text/plain")

  doAssert ctx.response.getHeader("CONTENT-TYPE") == @[
      "text/html; charset=UTF-8", "text/plain"]
```