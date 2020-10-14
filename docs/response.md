# Response

## Respond by types

You can specify different responses by types.
- htmlResponse -> HTML format
- plainTextResponse -> Plain Text format
- jsonResponse -> Json format

## Respond by error code

- error404 -> return 404
- redirect -> return 301 and redirect to a new page
- abort -> return 401

## Other utils

You can set the cookie and header of the response.

`SetCookie`: sets the cookie of the response.
`DeleteCookie`: deletes the cookie of the response.
`setHeader`: sets the header values of the response.
`addHeader`: adds header values to the existing `HttpHeaders`.

## Send user-defined response

`Prologue` framework will automatically send the final response to the client. You just need to set the attributes of response.

It also supports sending response by yourself. For example you can use `ctx.respond` to send data to the client.

```nim
proc sendResponse(ctx: Context) {.async.} =
  await ctx.respond(Http200, "data")
```

But this will leads that "data" message is sent twice, it's ok for some situations. For example, you may want to send another message, you can change the body of the response. 

```nim
proc sendResponse(ctx: Context) {.async.} =
  await ctx.respond(Http200, "data")
  ctx.response.body = "message"
```

First this handler will send "data" to the client, then the handler will send "message" to the client. However, this may be not the intended behaviour. You want to make sure when you send response by yourself, the framework shouldn't handle the response anymore.

You can set the `handled` attributes of context to true. Now the framework won't handle `ctx.response` any more, even the error handler won't work. Only "data" message is sent to the client.

```nim
proc sendResponse(ctx: Context) {.async.} =
  await ctx.respond(Http200, "data")
  ctx.handled = true
  ctx.response.code = Http500
  ctx.response.body = "message"
```