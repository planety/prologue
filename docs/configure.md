# Configuration

When starting a project, you need to configure your application.

## Simple settings

For small program, you could use the default `settings` which is provided by `Prologue`.

```nim
import prologue

var app = newApp()
app.run()
```

You may want to specify settings by yourself. `Prologue` provides `newSettings` function to create a new settings. The program below creates a new settings with `debug = false`. This will disable the default logging.

```nim
import prologue

let settings = newSettings(debug = false)
var app = newApp(settings = settings)
app.run()
```

You can also read settings from `.env` file. `Prologue` provides `loadPrologueEnv` to read data from `.env` file. You can use `get` or `getOrDefault` to retrieve the value.

```nim
import prologue

let
  env = loadPrologueEnv(".env")
  settings = newSettings(appName = env.getOrDefault("appName", "Prologue"),
                         debug = false,
                         port = Port(env.getOrDefault("port", 8080))
    )

var app = newApp(settings = settings)
app.run()
```

## Config file

You need to specify a config file for a big project. `Prologue` provides `loadSettings` to read JSON file. You should give the path of the Json config file.

```nim
let settings = loadSettings(".config/config.debug.json")
var app = newApp(settings)
```

`.config/config.debug.json`

In config file, the `prologue` key must be present. The corresponding data will be used by framework. Among the corresponding data, the `secretKey` must be present and should not be empty. Otherwise, the program will raise exception. Other keys can be absent, they will be given a default value setting by `Prologue`.

Below is the type of settings:

```
address: string
port: int
debug: bool
reusePort: bool
appName: string
secretKey: string
bufSize: int
```

```json
{
  "prologue": {
    "address": "",
    "port": 8080,
    "debug": true,
    "reusePort": true,
    "appName": "",
    "secretKey": "Set by yourself",
    "bufSize": 40960
  },
  "name": "debug"
}
```

`Prologue` also supports automatically loading configure file by environment variables. The `.config` directory must be present in the current path(in the same directory as the main program). If you don't set the environment variable(namely `PROLOGUE`) or the value is `default`, the application will read `.config/config.json` file. Otherwise, if you set the `PROLOGUE` environment variable to `custom`, the application will read `.config/config.custom.json`. The common names includes `debug` and `production`. If the file doesn't exist, it will raise exception.

```nim
import prologue

var app = newAppQueryEnv()
app.run()
```

