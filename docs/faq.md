1. If you use Linux or MacOS, you can use `--threads:on` to enable the multi-threads HTTP server.

2. If you use windows and want to use multi-threads HTTP server, make sure use
latest Nim devel version and enable `--threads:on`. In this situation, you can
use `-d:usestd` to use `asynchttpserver`. Notes that multi threads may be slower than single-thread in windows!

3. If you want to benchmark `prologue` or release you programs, make sure set `settings.debug` = false.

```nim
let
  # debug attributes must be false
  env = loadPrologueEnv(".env")
  settings = newSettings(appName = env.getOrDefault("appName", "Prologue"),
                         debug = false,
                         port = Port(env.getOrDefault("port", 8787)),
                         staticDirs = [env.get("staticDir")],
                         secretKey = env.getOrDefault("secretKey", "")
    )
```

or in `.env` file, set `debug = false`.

```nim
# Don't commit this to source control.
# Eg. Make sure ".env" in your ".gitignore" file.
debug=false # change this
port=8787
appName=HelloWorld
staticDir=/static
secretKey=Pr435ol67ogue
```

There are two ways to disable logging messages:

(1) set `settings.debug` = false
(2) set a startup event

```nim
proc setLoggingLevel() =
  addHandler(newConsoleLogger())
  logging.setLogFilter(lvlInfo)


let 
  event = initEvent(setLoggingLevel)
var
  app = newApp(settings = settings, middlewares = @[debugRequestMiddleware()], startup = @[event])
```