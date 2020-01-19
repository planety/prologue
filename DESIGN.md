### Configure

#### config.ini

```ini
[logger]
consoleLogger = true
fileLogger = true
defaultFileLoggerPath = "app.log"

[app]
prologue.reload_templates = true

[server]
use = asynchttpserver 
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
  var app = initApp(settings = settings)
  app.addRoute("/", home, "", HttpGet)
  app.addRoute("/home", home, "", HttpGet)
  app.addRoute("/hello", hello, "", HttpGet)
  app.addRoute("/hello", hello, "advanced"， HttpGet)
  app.addRoute("/templ", templ, "tempalte", HttpGet)
  app.addRoute("/hello/<name>", helloName, "name", HttpGet, )
  # support file urls
  app.addRoute(basePath = "mywebsite", fileName = "mywebsite.urls")
  return app
```

### View

#### view.nim

```nim
import tables
from prologue import view

import config


proc hello*(request: Request) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"
    
proc home*(request: Request) {.async.} =
  resp "<h1>Home</h1>"
    
proc templ*(request: Request) {.async.} =
  resp templateRender("template.html", {"name": "string"})
    
proc helloName*(request: Request) {.async.} =
  resp "Hello, " & request.params["name"]


let settings = initSettings(appName = "Prologue")
var app = setup(settings)
app.run()
```

- Return Html
- Render Html

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





