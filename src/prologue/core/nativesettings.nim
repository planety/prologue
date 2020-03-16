import mimetypes, json
from nativeSockets import Port

from types import SecretKey, EmptySecretKeyError, len
from urandom import randomSecretKey


type
  Settings* = ref object
    data: JsonNode

  CtxSettings* = ref object
    mimeDB*: MimeDB


proc hasKey*(settings: Settings, key: string): bool {.inline.} =
  settings.data.hasKey(key)

proc `[]`*(settings: Settings, key: string): JsonNode {.inline.} =
  settings.data[key]

proc getOrDefault*(settings: Settings, key: string): JsonNode {.inline.} =
  settings.data.getOrDefault(key)

proc newCtxSettings*(): CtxSettings {.inline.} =
  CtxSettings(mimeDB: newMimetypes())

proc newSettings*(configPath: string): Settings {.inline.} =
  # make sure reserved keys must appear in settings
  result = Settings(data: parseFile(configPath))
  for item in ["port", "debug", "reusePort", "staticDirs", "secretKey", "appName"]:
    if not result.hasKey(item):
      raise newException(ValueError, "Reserved keys must appear in settings!")

proc newSettings*(port = Port(8080), debug = true, reusePort = true,
    staticDirs = "static", secretKey = randomSecretKey(8),
        appName = "", dbPath = ""): Settings {.inline.} =
  if secretKey.len == 0:
    raise newException(EmptySecretKeyError, "Secret key can't be empty!")

  result = Settings(data: %* {"port": port.int, "debug": debug,
            "resuePort": reusePort, "staticDirs": [staticDirs],
            "secretKey": string(secretKey), "appName": appName,
            "dbPath": dbPath
    })
