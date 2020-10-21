import ../../../src/prologue
import pkg/yaml


proc yaml2json(configPath: string): JsonNode =
  result = yaml.loadToJson(readFile(configPath))[0]

proc hello(ctx: Context) {.async.} =
  resp "Hello"

var app = newAppQueryEnv(Yaml, yaml2json)
app.get("/", hello)
app.run()
