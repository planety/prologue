# FAQ

## Threads

`Prologue` supports two HTTP server: `httpbeast` and `asynchttpserver`. If you are in Linux or MacOS, use `--threads:on` to enable the multi-threads HTTP server. If you are in windows, `threads` should not be used. You can use `-d:usestd` to switch to `asynchttpserver` in Linux or MacOS.

## Benchmarking and debug

If you want to benchmark `prologue` or release you programs, make sure set `settings.debug` = false.

```nim
let
  # debug attributes must be false
  env = loadPrologueEnv(".env")
  settings = newSettings(appName = env.getOrDefault("appName", "Prologue"),
                         debug = false,
                         port = Port(env.getOrDefault("port", 8080)),
                         secretKey = env.getOrDefault("secretKey", "")
    )
```

or in `.env` file, set `debug = false`.

```nim
# Don't commit this to source control.
# Eg. Make sure ".env" in your ".gitignore" file.
debug=false # change this
port=8080
appName=HelloWorld
staticDir=/static
secretKey=Pr435ol67ogue
```

## Disable logging

There are two ways to disable logging messages:

- set `settings.debug` = false
- set a startup event

```nim
proc setLoggingLevel() =
  addHandler(newConsoleLogger())
  logging.setLogFilter(lvlInfo)


let 
  event = initEvent(setLoggingLevel)
var
  app = newApp(settings = settings, startup = @[event])
```

## Avoid using a function name which is same to the module name.

`src/index.nim`

```nim
proc index(ctx: Context) {.async.} =
  ...
```

## Use the full path of JS, CSS files.

For instance in your HTML file use `templates/some.js` instead of `some.js`.

## Run in async mode

The server can run in async mode, this is useful to perform other tasks beside
accepting connections.

```nim
import prologue

proc handler(ctx: Context) {.async.} =
  resp "Hello world"

let settings = newSettings(port = Port(8000))
let app = newApp(settings)
app.all("/*$", handler)
waitFor app.runAsync()

```

