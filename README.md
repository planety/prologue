![Build Status](https://github.com/planety/prologue/workflows/Test%20Prologue/badge.svg)
[![Build Status](https://dev.azure.com/xzsflywind/xlsx/_apis/build/status/planety.prologue?branchName=devel)](https://dev.azure.com/xzsflywind/xlsx/_build/latest?definitionId=4&branchName=devel)
![Build Status](https://travis-ci.org/planety/prologue.svg?branch=devel)

![License: Apache-2.0](https://img.shields.io/github/license/planety/prologue)
[![Version](https://img.shields.io/github/v/release/planety/prologue?include_prereleases)](https://github.com/planety/prologue/releases)
[![buy me a coffee](https://img.shields.io/badge/donate-buy%20me%20a%20coffee-orange.svg)](https://github.com/planety/prologue#donate)
[![Discord](https://img.shields.io/discord/718010516034945045?label=Discord&logo=discord&logoColor=white)](https://discord.gg/e2dB4WT)

# Prologue

What's past is prologue.

## Purpose
Prologue is a Full-Stack Web Framework which is
ideal for building elegant and high performance
web services.

**Reduce magic. Reduce surprise.**

## Documentation

<table class="tg">
<tbody>
  <tr>
    <td class="tg-0pky">Documentation</td>
    <td class="tg-c3ow" text-align="center" colspan="2"><a href="https://planety.github.io/prologue" target="_blank" rel="noopener noreferrer">Index Page</a></td>
  </tr>
  <tr>
    <td class="tg-c3ow">Core API</td>
    <td class="tg-0pky"><a href="https://planety.github.io/prologue/coreapi/theindex.html" target="_blank" rel="noopener noreferrer">Index Page</a></td>
    <td class="tg-0pky"><a href="https://planety.github.io/prologue/coreapi/application.html" target="_blank" rel="noopener noreferrer">Search Page</a></td>
  </tr>
  <tr>
    <td class="tg-c3ow">Full API</td>
    <td class="tg-0pky"><a href="https://planety.github.io/prologue/plugin/theindex.html" target="_blank" rel="noopener noreferrer">Index Page</a></td>
    <td class="tg-0pky"><a href="https://planety.github.io/prologue/plugin/index.html" target="_blank" rel="noopener noreferrer">Search Page</a></td>
  </tr>
</tbody>
</table>

## Feature

- Core
  - [x] Base on `httpx` and `asynchttpserver`
  - [x] Configure and Settings
  - [x] Context
  - [x] Param and Query Data
  - [x] Form Data
  - [x] Static Files
  - [x] Middleware
  - [x] Simple Route
  - [x] Regex Route
  - [x] DSL Route
  - [x] CORS Response
  - [x] Signing
  - [x] Cookie
  - [x] Session
  - [x] Cache
  - [x] Startup and Shutdown Events
  - [x] URL Building
  - [x] Data Validation
  - [x] Exception Handler
  - [x] Cross-Site Request Forgery
  - [x] Cross-Site Scripting (XSS) Protection(Karax quote string automatically)
  - [x] Clickjacking Protection
  - [x] Authentication
  - [x] I18n
  - [x] Command line tools
  - [x] Mocking test

- Plugin
  - [x] Minimal OpenAPI support
  - [x] Template(Using Karax Native)
  - [x] Websocket support(https://github.com/xflywind/websocketx)
  - [x] Test Client(Using httpclient)


## Installation

First you should install [Nim](https://nim-lang.org/) language which is an elegant and high performance language. Follow the [instructions](https://nim-lang.org/install.html) and set environment variables correctly.

Then you can use `nimble` command to install `prologue`.

```bash
nimble install prologue
```

## Usage

### Hello World

```nim
import prologue

proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

let app = newApp(settings = newSettings())
app.addRoute("/", hello)
app.run()
```
`
Run **app.nim**(`nim c -r app.nim`). Now the server is running at `localhost:8080`.

### More examples
- [HelloWorld](https://github.com/planety/prologue/tree/devel/examples/helloworld)
- [ToDoList](https://github.com/planety/prologue/tree/devel/examples/todolist)
- [ToDoApp](https://github.com/planety/prologue/tree/devel/examples/todoapp)
- [Blog](https://github.com/planety/prologue/tree/devel/examples/blog)
- [Additional examples repository](https://github.com/planety/prologue-examples)

### Extensions

If you need more extensions, you can refer to [awesome prologue](https://github.com/planety/awesome-prologue) and [awesome nim](https://github.com/xflywind/awesome-nim#web).


## Donate

Thanks for supporting me!

[buy me a coffee](https://www.buymeacoffee.com/flywind)

[patreon](https://www.patreon.com/flywind)


## Stars
[![Stargazers over time](https://starchart.cc/planety/prologue.svg)](https://starchart.cc/planety/prologue)
