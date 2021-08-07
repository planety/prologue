# Static Files

Prologue supports serving static files.

## Send static file Response

You can use `staticFileResponse` to make a static file response.

```nim
proc home(ctx: Context) {.async.} =
  await ctx.staticFileResponse("hello.html", "")
```

## Download files

User maybe want to download some files from the server. You can use `staticFileResponse` to send the file to be downloaded. 

```nim
proc downloadFile(ctx: Context) {.async.} =
  await ctx.staticFileResponse("index.html", "static", downloadName = "download.html")
```

## Serve static files

`staticfile` is implemented as middleware. It should be imported first. You can specify the path of static directories. `staticDirs` is of `varargs[string]` type. It contains all
the directories of static files which will be checked in every request.

```nim
import prologue
import prologue/middlewares/staticfile


var app = newApp(settings = settings)
app.use(staticFileMiddleware(env.get("staticDir")))
# add your routes
app.run()
```

Multiple directories:

```nim
import prologue
import prologue/middlewares/staticfile


var app = newApp(settings = settings)
app.use(staticFileMiddleware("public", "templates"))
# Or seq[string]
# app.use(staticFileMiddleware(@["public", "templates"]))
# Or array[N, string]
# app.use(staticFileMiddleware(["public", "templates"]))
app.addRoute(urls.urlPatterns, "")
app.run()
```

## Serving Favicon

You may want to add an icon for your website, you can use a favicon. The browser maybe request `/favicon.ico` to find an icon. `redirctTo` is handy for this work. `dest` is the real path of a favicon. For example, you can put it under `static` directory.

```nim
import prologue
from prologue/middlewares/staticfile import redirectTo


var app = newApp()
app.get("/favicon.ico", redirectTo("/static/favicon.ico"))
app.run()
```
