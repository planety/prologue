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
  app.addRoute(Path("", home, "/home"), HttpGet)
  app.addRoute(Path("", hello, "/hello"), HttpGet)
  app.addRoute(Path("mywebsite", include("mywebsite.urls")))
  app.addRoute(Path("advanced", templ, "/templ"), HttpGet, render = "templ.html")
  app.addRoute(Path("", helloName, "/hello/<name>"), HttpGet)
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
  resp {"name": "string"}.toTable
    
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

```nim
from prologue import test
```





