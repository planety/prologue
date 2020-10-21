import ../../../src/prologue
import ./utils
import pkg/parsetoml


proc toml2json(configPath: string): JsonNode = 
  result = parsetoml.parseFile(configPath).toRealJson

proc hello(ctx: Context) {.async.} =
  resp "Hello"

var app = newAppQueryEnv(Toml, toml2json)
app.get("/", hello)
app.run()
