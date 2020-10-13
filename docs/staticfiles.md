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
app.addRoute(urls.urlPatterns, "")
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
