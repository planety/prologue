# Quick Start

## hello world

Now Let's begin a quick tour of `Prologue`.

```nim
# app.nim
import prologue


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"


let settings = newSettings()
var app = newApp(settings = settings)
app.addRoute("/", hello)
app.run()
```

This is a very basic "Hello Prologue" example.Run this script, visit [http://localhost:8080](http://localhost:8080) and you will
see "Hello, Prologue!" in your browser! Here is how it works.

First we `import prologue` to include all things we need in this example.

Then let's look at `hello` function. It generates html or plain text or json or something else to our default http server(asynchttpserver). Function parameters `ctx` is of `Context` type. `Context` carry all things in every request. It includes `request` from http server and `response` which we transfer to http server Correspondingly and other useful attributes. In function body, we can find `resp`. `resp` is handy for generating response we need. It is equal to `ctx.response = initResponse("<h1>Hello, Prologue!</h1>")`.

Next let's configure our application. For this basic
example, we will use default settings. You can specify parameters of `newSettings` of course. You can change to other `port` or set `debug` flag.

Next let's add route to our application. Finally just `run` our application.

## Command line tool

You can also install [logue](https://github.com/planety/logue) to initialize your
program.

```
nimble install logue
```

Make sure `~/.nimble/bin` is in your environment variables.

Type command `logue init helloworld` to initialize. This will create program
structure like this:

```
- helloworld
  .env
  app.nim
  urls.nim
  views.nim
```

You must switch to `/.../helloworld` directory to run `app.nim`.
