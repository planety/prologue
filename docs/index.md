![Build Status](https://github.com/planety/prologue/workflows/Test%20Prologue/badge.svg)
[![Build Status](https://dev.azure.com/xzsflywind/xlsx/_apis/build/status/planety.prologue?branchName=devel)](https://dev.azure.com/xzsflywind/xlsx/_build/latest?definitionId=4&branchName=devel)
![Build Status](https://travis-ci.org/planety/prologue.svg?branch=devel)

[![License: BSD-3-Clause](https://img.shields.io/github/license/planety/prologue)](https://opensource.org/licenses/BSD-3-Clause)
[![Version](https://img.shields.io/github/v/release/planety/prologue?include_prereleases)](https://github.com/planety/prologue/releases)
[![buy me a coffee](https://img.shields.io/badge/donate-buy%20me%20a%20coffee-orange.svg)](https://github.com/planety/prologue#donations)


# Prologue

What's past is prologue.

## Purpose

`Prologue` is a powerful and flexible web framework written in Nim.
It is ideal for building elegant and high performance web services.

**Reduce magic. Reduce surprise.**

## Documentation

<table class="tg">
<tbody>
  <tr>
    <td class="tg-0pky">Documentation</td>
    <td class="tg-c3ow" colspan="2"><a href="https://planety.github.io/prologue" target="_blank" rel="noopener noreferrer">Index Page</a></td>
  </tr>
  <tr>
    <td class="tg-c3ow">Core API</td>
    <td class="tg-0pky"><a href="https://planety.github.io/prologue/coreapi/theindex.html" target="_blank" rel="noopener noreferrer">Index Page</a></td>
    <td class="tg-0pky"><a href="https://planety.github.io/prologue/coreapi/application.html" target="_blank" rel="noopener noreferrer">Search Page</a></td>
  </tr>
  <tr>
    <td class="tg-c3ow">Full API</td>
    <td class="tg-0pky"><a href="https://planety.github.io/prologue/plugin/theindex.html" target="_blank" rel="noopener noreferrer">Index Page</a></td>
    <td class="tg-0pky"><a href="https://planety.github.io/prologue/plugin/plugin.html" target="_blank" rel="noopener noreferrer">Search Page</a></td>
  </tr>
</tbody>
</table>

## Installation

First you should install [Nim](https://nim-lang.org/) language which is an elegant and high performance language. Follow the [instructions](https://nim-lang.org/install.html) and set environment variables correctly.

Then you can use `nimble` command to install prologue.

```bash
nimble install prologue
```

`Prologue` also provides some extensions. You can use `logue extension` to install all of them. If you just want to install one of them, you can use `logue extension module` for example `logue extension redis`.

## Usage

### Hello World

```nim
# app.nim
import prologue

proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

let app = newApp()
app.addRoute("/", hello)
app.run()
```

Run **app.nim** ( `nim c -r app.nim` ). Now the server is running at `localhost:8080`.

### Another example

```nim
# app.nim
import prologue
import prologue/middlewares


# Async Function
proc home*(ctx: Context) {.async.} =
  resp "<h1>Home</h1>"

proc helloName*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.getPathParams("name", "Prologue") & "</h1>"

proc doRedirect*(ctx: Context) {.async.} =
  resp redirect("/hello")

proc login*(ctx: Context) {.async.} =
  resp loginPage()

proc do_login*(ctx: Context) {.async.} =
  resp redirect("/hello/Nim")


let settings = newSettings(appName = "Prologue")
var app = newApp(settings = settings)
app.use(debugRequestMiddleware())
app.addRoute("/", home, @[HttpGet, HttpPost])
app.addRoute("/home", home, HttpGet)
app.addRoute("/redirect", doRedirect, HttpGet)
app.addRoute("/login", login, HttpGet)
app.addRoute("/login", do_login, HttpPost, middlewares = @[debugRequestMiddleware()])
app.addRoute("/hello/{name}", helloName, HttpGet)
app.run()
```

Run **app.nim** (`nim c -r app.nim`). Now the server is running at `localhost:8080`.

### More examples
- [HelloWorld](https://github.com/planety/prologue/tree/devel/examples/helloworld)
- [ToDoList](https://github.com/planety/prologue/tree/devel/examples/todolist)
- [ToDoApp](https://github.com/planety/prologue/tree/devel/examples/todoapp)
- [Blog](https://github.com/planety/prologue/tree/devel/examples/blog)
- [Additional examples repository](https://github.com/planety/prologue-examples)

### Extensions

If you need more extensions, you can refer to [awesome prologue](https://github.com/planety/awesome-prologue) and [awesome nim](https://github.com/xflywind/awesome-nim#web).

## Donations

Thanks for supporting me.

[patreon](https://www.patreon.com/flywind)


## Stars
[![Stargazers over time](https://starchart.cc/planety/prologue.svg)](https://starchart.cc/planety/prologue)
