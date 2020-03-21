import mimetypes, json, tables, strtabs
from nativesockets import Port

from ./types import SecretKey, EmptySecretKeyError, len
from ./urandom import randomString


type
  Settings* = ref object
    port*: Port
    debug*: bool
    reusePort*: bool
    staticDirs*: seq[string]
    appName*: string
    data: JsonNode

  CtxSettings* = ref object
    mimeDB*: MimeDB
    config*: TableRef[string, StringTableRef]


proc hasKey*(settings: Settings, key: string): bool {.inline.} =
  settings.data.hasKey(key)

proc `[]`*(settings: Settings, key: string): JsonNode {.inline.} =
  settings.data[key]

proc getOrDefault*(settings: Settings, key: string): JsonNode {.inline.} =
  settings.data.getOrDefault(key)

proc newCtxSettings*(): CtxSettings {.inline.} =
  CtxSettings(mimeDB: newMimetypes(), config: newTable[string, StringTableRef]())

proc newSettings*(port = Port(8080), debug = true, reusePort = true,
    staticDirs: openArray[string] = ["static"], secretKey = randomString(8),
        appName = ""): Settings {.inline.} =
  if secretKey.len == 0:
    raise newException(EmptySecretKeyError, "Secret key can't be empty!")

  result = Settings(port: port, debug: debug, reusePort: reusePort,
            staticDirs: @staticDirs, appName: appName,
            data: %* {"secretKey": secretKey})

proc newSettings*(configPath: string, port = Port(8080), debug = true, reusePort = true,
      staticDirs: openArray[string] = ["static"],
        appName = ""): Settings {.inline.} =
  # make sure reserved keys must appear in settings
  var data = parseFile(configPath)
  result = Settings(port: port, debug: debug, reusePort: reusePort,
            staticDirs: @staticDirs, appName: appName,
            data: data)
