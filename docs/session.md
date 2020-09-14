# Session

The session helps with storing users' state.

## Session based on signed cookie
This session is based on signed cookie. **It is not safe**. You must not use it to store sensitive or important infos except for testing.

Prologue provides `sessionMiddleware` to you.

## Usage

First you should register `sessionMiddleware` in global middlewares or hanler's middlewares.

```nim
var app = newApp(settings = settings, middlewares = @[sessionMiddleware(secretKey = secretKey.SecretKey)])
```

Then you can use session in all handlers. You can set/get/clear session.

```nim
proc login*(ctx: Context) {.async.} =
  ctx.session["flywind"] = "123"
  ctx.session["ordontfly"] = "345"
  resp "<h1>Hello, Prologue!</h1>"

proc logout*(ctx: Context) {.async.} =
  resp $ctx.session
```

More session examples are in [Session](https://github.com/planety/prologue/tree/master/examples/session) and [Blog](https://github.com/planety/prologue/tree/master/examples/blog)

