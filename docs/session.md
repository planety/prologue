# Session

The session helps with storing users' state. If you want to use `session` or `flash` messages, you must use `sessionMiddleware` first.

## Session based on signed cookie
This session is based on signed cookie. **It is not safe**. You must not use it to store sensitive or important info except for testing.

Prologue provides you with `sessionMiddleware`.

### Usage

First you should register `sessionMiddleware` in global middlewares or handler's middlewares.

```nim
import prologue
import prologue/middlewares/sessions/signedcookiesession

let settings = newSettings()
var app = newApp(settings = settings)
app.use(sessionMiddleware(settings))
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

More session examples are in [Session](https://github.com/planety/prologue/tree/devel/examples/session) and [Blog](https://github.com/planety/prologue/tree/devel/examples/blog)


## Session based on memory

The usage of memory session is similar to signed cookie session. Just change the import statement to `import prologue/middlewares/sessions/memorysession`. This is meant for testing too. Because the data will be lost if the program stops.

```nim
import prologue
import prologue/middlewares/sessions/memorysession


let settings = newSettings()
var app = newApp(settings)
app.use(sessionMiddleware(settings))
```

## Session based on redis

You should install `redis` first(`logue extension redis`).

```nim
import prologue
import prologue/middlewares/sessions/redissession


let settings = newSettings()
var app = newApp(settings)
app.use(sessionMiddleware(settings))
```

## Flash messages

Sometimes you need to store some messages to session, then you can visit these messages in the next request. They will be used once. Once you have visit these messages, they will be popped from the session. You must use one of session middleware above.

```nim
import src/prologue
import src/prologue/middlewares/signedcookiesession
import std/with


proc hello(ctx: Context) {.async.} =
  ctx.flash("Please retry again!")
  resp "Hello, world"

proc tea(ctx: Context) {.async.} =
  let msg = ctx.getFlashedMsg(FlashLevel.Info)
  if msg.isSome:
    resp msg.get
  else:
    resp "My tea"

let settings = newSettings()
var app = newApp(settings)

with app:
  use(sessionMiddleware(settings))
  get("/", hello)
  get("/hello", hello)
  get("/tea", tea)
  run()
```
