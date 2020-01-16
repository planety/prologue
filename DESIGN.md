### Configure

#### config.ini

```ini
[app:main]
prologue.reload_templates = true

[server:main]
use = egg:asynchttpserver 
listen = localhost:8080
```

#### config.nim

- Return Server

```nim
import strtabs
import views
import prologue


proc setup(settings: Settings): Prologue =
  var app = Prologue(settings: Settings)
  app.addRoute('/home', home, HttpGet)
  app.addRoute('/hello', hello, HttpGet)
  app.addRoute("/templ", templ, HttpGet, render = "templ.html")
  app.addRoute("/hello/<name>", HttpGet,helloName)
  return app
```

### View

#### view.nim

```nim
import tables
from prologue import view

proc hello*(request: Request): Future[string] {.async.} =
  resp "<h1>Hello, Prologue!</h1>"
    
proc home*(request: Request): Future[string] {.async.} =
  resp "<h1>Home</h1>"
    
proc templ*(request: Request): Future[string] {.async.} =
  resp {"name": "string"}.toTable
    
proc helloName*(request: Request): Future[string] {.async.} =
  resp "Hello, " & resuest.params["name"]
```

- Return Html
- Render Html

### Tests

#### test.nim

- Test Module

```nim
from prologue import test
```





