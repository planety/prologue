# Quick Start

## hello world

Now Let's begin a quick tour of `Prologue`.

```nim
# app.nim
import prologue

proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

var app = newApp()
app.addRoute("/", hello)
app.run()
```

This is a very basic "Hello Prologue" example. Run this script, then visit [http://localhost:8080](http://localhost:8080) and you will
see "Hello, Prologue!" in your browser! Here is how it works.

First we `import prologue` to include all things we need in this example(for examples `resp` macros).

Then let's look at `hello` function. It generates html or plain text or json or something else sent to our HTTP server. The parameter `ctx` is of `Context` type. `Context` carries all things which we can use in our handler in each request. It contains `request` information from HTTP server, `response` information which we transfer to HTTP server Correspondingly and other useful attributes. In the body of function, we can find `resp` macros. `resp` is handy for generating response we need. It is equal to `ctx.response = initResponse("<h1>Hello, Prologue!</h1>")`.

Next let's configure our application. For this basic
example, we use default settings. You can specify parameters of `newSettings` too. For example change `port` attribute or set `debug` flag.

Next add route to our application. `"/"` is the URL we can visit in the web browser. `Hello` is the handler which processes the request from the web browser and sends `"<h1>Hello, Prologue!</h1>"` to the web browser.

Finally use `nim c -r app.nim` to run our application. Visit `localhost:8080`, `Hello, Prologue!` is displayed in your browser.

![hello world](assets/quickstart/hello.jpg)

## Command line tool

`logue` can be used to initialize your
program.

Make sure `~/.nimble/bin` is in your environment variables.

Type command `logue init helloworld` to initialize a new project. This will create a program
structure like this:

```
- helloworld
  - .env
  - app.nim
  - urls.nim
  - views.nim
```

You must switch to `/.../helloworld` directory to run `app.nim`. For example, you can type `logue run` and open the browser to visit the URL.
