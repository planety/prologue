Now Let's begin a quick tour of `Prologue`.

```nim
# app.nim
import asyncdispatch
import prologue


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"


let settings = newSettings()
var app = initApp(settings = settings)
app.addRoute("/", hello)
app.run()
```

This is a very basic "Hello Prologue" example.Run this script, visit [http://localhost:8080](http://localhost:8080) and you will
see "Hello, Prologue!" in your browser! Here is how it works.
