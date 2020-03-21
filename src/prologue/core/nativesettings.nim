import mimetypes, json, tables, strtabs
from nativesockets import Port

from ./types import SecretKey, EmptySecretKeyError, len
from ./urandom import randomString


type
  Settings* = ref object
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

  result = Settings(data: %* {"port": port.int, "debug": debug,
            "reusePort": reusePort, "staticDirs": staticDirs,
            "secretKey": secretKey, "appName": appName
    })

proc newSettings*(configPath: string): Settings {.inline.} =
  # make sure reserved keys must appear in settings
  var data = parseFile(configPath)
  let defaultSettings = newSettings()
  for key in ["port", "debug", "reusePort", "staticDirs", "secretKey",
      "appName"]:
    if not result.hasKey(key):
      data[key] = defaultSettings[key]

  let secretKey = data.getOrDefault("secretKey").getStr
  if secretKey.len == 0:
    raise newException(EmptySecretKeyError, "Secret key can't be empty!")
  result = Settings(data: data)
