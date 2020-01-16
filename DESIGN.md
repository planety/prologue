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
from prologue import config


proc setup(settings: StringTableRef):
  var config = Configure(settings:settings)
  config.addRoute('/home', home, HttpGet)
  config.addRoute('/hello', hello, HttpGet)
  config.addRoute("/templ", templ, HttpGet, render = "templ.html")
  config.addRoute("/hello/<name>", HttpGet,helloName)
  return config.makeApp()
```

### View

#### view.nim

```nim
import tables
from prologue import view

proc hello*(request: Request): string =
  resp "<h1>Hello, Prologue!</h1>"
    
proc home*(request: Request): string =
  resp "<h1>Home</h1>"
    
proc templ*(request: Request): string =
  resp {"name": "string"}.toTable
    
proc helloName*(request: Request): string =
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





