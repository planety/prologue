### Configure

#### config.ini

```ini
[logger]
consoleLogger = true
consoleLoggerLevel = "warning"
consoleLoggerFormat = "[$time] - $levelname: "
fileLogger = true
defaultFileLoggerPath = "app.log"

[app]
debug = false
auto_json = false
reload_templates = true
static_folders = "/static"
secure_proxy_ssl_header = none

[db]
sqlite = ":memory"

[plugins]
starlight_cache = true
starlight_oauth = true
starlight_admin = true
starlight_session = true

[plugins_options]
session_secret = "My session secret."

[server]
use = "asynchttpserver"
listen = localhost:8080
```

#### config.nim

- Return Server

Support simple route or single file urls.

```nim
import strtabs
import views
import prologue


proc setup(settings: Settings): Prologue =
  # We create an instance of app, the first argument is settings.
  var app = initApp(settings = settings)
  # you can specify default options from files.
  # for example, debug options.
  # var app = initApp(config = "config.debug") 
  let routes = [HttpRoute("/test", test, "", HttpGet), WebSocket("websocket", find)]
  app.addRoute(routes)
  # May change later
  # addRoute tell framework what URLs should trigger our handler function. 
  app.addRoute("/", home, "", HttpGet)
  app.addRoute("/home", home, "", HttpGet)
  app.addRoute("/hello", hello, "", HttpGet)
  app.addRoute("/hello", hello, "advanced", HttpGet)
  app.addRoute("/templ", templ, "tempalte", HttpGet)
    app.addRoute("/redirect", testRedirect, "", HttpGet)
  app.addRoute("/hello/<name>", helloName, "name", HttpGet)
  # support file urls
  app.addRoute(basePath = "mywebsite", fileName = "mywebsite.urls")
  return app
```

mywebsite.urls

```text
Route("/", home, "", HttpGet)
WebSocketRoute("/", hello, HttpGet)
Mount('/static', StaticFiles(directory="static"))
```

### View

#### view.nim

```nim
import tables
from prologue import view

import config


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc home*(ctx: Context) {.async.} =
  resp "<h1>Home</h1>"

proc templ*(ctx: Context) {.async.} =
  resp {"name": "string"}.toTable

proc helloName*(ctx: Context) {.async.} =
  resp "<h1>Hello, " & ctx.params.getOrDefault("name", "Prologue") & "</h1>"

proc testRedirect*(ctx: Context) {.async.} =
  await redirect(ctx, "/hello")

let settings = initSettings(appName = "Prologue")
var app = setup(settings)
app.run()
```

- Return Html
- Render Html

### Hook

- before request
- after request

### Tests

#### test.nim

- Test Module

Support Test Client.

```nim
from prologue import testclient


suite "Test Prologue":
  let
    address = "127.0.0.1"
    port = Port(8080)
    baseUrl = ""

  test "route hello":
    check testRoute("/hello") == "<h1>Hello, Prologue!</h1>"

  test "route home":
    check testRoute("/home") == "<h1>Home</h1>"
```





