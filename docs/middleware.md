# Middlewares

## Existing middlewares

Prologue provides various middlewares out of the box.

### Static File Serving
Allows serving files directly from the prologue webserver. It is recommended to only use this during development, as serving static files (e.g. images) is typically done by the reverse proxy server in production.

Please note that the filepaths you specify there are relative to the position of the binary, so where you place the binary from matters!

If you run the lower example locally on port 8080, a file in the folder `media/image.png` will be served on the URL `localhost:8080/media/image.png`

```nim
import prologue
import prologue/middlewares/staticfile

var app = newApp()
app.use(staticFileMiddleware("media")) # 
app.run()
```

## Write your own middleware

Middlewares are like an onion.

```
a request -> middlewareA does something -> middlewareB does something
-> handler does something -> middlewareB does something -> middlewareA does something -> a response
```

Don't forget `await switch(ctx)` to enter the next middleware or handler.

Then you can set global middlewares which are visible to all handlers. Or you can make them only
visible to some middlewares.

```nim
import logging
import prologue


proc hello(ctx: Context) {.async.} =
  discard

proc myDebugRequestMiddleware*(appName = "Prologue"): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    logging.info "debugRequestMiddleware->begin"
    # do something before
    await switch(ctx)
    # do something after
    logging.info "debugRequestMiddleware->End"


var app = newApp()

app.use(myDebugRequestMiddleware())
app.addRoute("/", hello, HttpGet, middlewares = @[myDebugRequestMiddleware()])
```

You can also put some variables in closure environments, but be careful it is error-prone when using multi-threads. You must know the differences between GC options(thread local heap vs shared heap) and what's the use of `gcsafe`. 

```nim
proc sessionMiddleware(): HandleAsync =
  var memorySessionTable = newTable[string, string]()

  result = proc(ctx: Context) {.async.} =
    memorySessionTable["test"] = "prologue"
```

You can put your middleware plugin in [collections](https://github.com/planety/awesome-prologue).

## Write reusable handler

Every handler in `Prologue` is a closure function. It is flexible to create a reusable components.

```nim
import prologue


proc home(ctx: Context) {.async.} =
  resp "home"

proc redirectTo(
  dest: string
): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    resp redirect(dest)


var app = newApp()
app.get("/", home)
app.get("/redirect", redirectTo("/"))
app.run()
```

## Use built-in middleware

`prologue` also supplies some middleware plugins, you can directly import `middlewares`.

It contains `cors`, `clickjacking`, `csrf`, `utils` and `auth` middlewares.

```nim
import prologue/middlewares
```

For better compilation time, you could import them directly.

```nim
import prologue/middlewares/auth
# or
import prologue/middlewares/utils
# or
import prologue/middlewares/cors
# or
import prologue/middlewares/clickjacking
# or
import prologue/middlewares/csrf
```

For session middlewares, you need to import them directly.

```nim
import prologue/middlewares/memorysession
# or
import prologue/middlewares/redissession
# or
import prologue/middlewares/signedcookiesession
```
