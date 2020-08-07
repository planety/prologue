import mimetypes, json, tables, strtabs
from nativesockets import Port

from ./types import SecretKey, EmptySecretKeyError, len
from ./urandom import randomString


type
  Settings* = ref object
    address*: string
    port*: Port
    debug*: bool
    reusePort*: bool
    staticDirs*: seq[string]
    appName*: string
    data: JsonNode

  CtxSettings* = ref object
    mimeDB*: MimeDB
    config*: TableRef[string, StringTableRef]

  LocalSettings* = ref object
    data*: JsonNode


proc hasKey*(settings: Settings, key: string): bool {.inline.} =
  settings.data.hasKey(key)

proc `[]`*(settings: Settings, key: string): JsonNode {.inline.} =
  settings.data[key]

proc getOrDefault*(settings: Settings, key: string): JsonNode {.inline.} =
  settings.data.getOrDefault(key)

proc newCtxSettings*(): CtxSettings {.inline.} =
  CtxSettings(mimeDB: newMimetypes(), config: newTable[string, StringTableRef]())

proc newLocalSettings*(data: JsonNode): LocalSettings {.inline.} =
  result = LocalSettings(data: data)

proc newLocalSettings*(configPath: string): LocalSettings {.inline.} =
  var data = parseFile(configPath)
  result = LocalSettings(data: data)

proc newSettings*(address = "", port = Port(8080), debug = true, reusePort = true,
                  staticDirs: openArray[string] = ["static"], secretKey = randomString(8),
                  appName = ""): Settings {.inline.} =
  if secretKey.len == 0:
    raise newException(EmptySecretKeyError, "Secret key can't be empty!")

  result = Settings(address: address, port: port, debug: debug, reusePort: reusePort,
                    staticDirs: @staticDirs, appName: appName,
                    data: %* {"secretKey": secretKey})


proc newSettings*(data: JsonNode, address = "", port = Port(8080), debug = true, reusePort = true,
                  staticDirs: openArray[string] = ["static"],
                  appName = ""): Settings {.inline.} =
  result = Settings(address: address, port: port, debug: debug, reusePort: reusePort,
                    staticDirs: @staticDirs, appName: appName,
                    data: data)

proc newSettings*(configPath: string, address = "", port = Port(8080), debug = true, reusePort = true,
                  staticDirs: openArray[string] = ["static"],
                  appName = ""): Settings {.inline.} =
  # make sure reserved keys must appear in settings
  var data = parseFile(configPath)
  result = Settings(address: address, port: port, debug: debug, reusePort: reusePort,
                    staticDirs: @staticDirs, appName: appName,
                    data: data)
