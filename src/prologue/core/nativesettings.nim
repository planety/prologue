# Copyright 2020 Zeshen Xing
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


import mimetypes, json, tables, strtabs
from nativesockets import Port

from ./types import SecretKey, EmptySecretKeyError, len
from ./urandom import randomString


type
  Settings* = ref object ## Global settings for all handlers.
    address*: string
    port*: Port
    debug*: bool
    reusePort*: bool
    staticDirs*: seq[string]
    appName*: string
    data: JsonNode

  CtxSettings* = ref object ## Context settings.
    mimeDB*: MimeDB
    config*: TableRef[string, StringTableRef]

  LocalSettings* = ref object ## local settings for corresponding handlers.
    data*: JsonNode


proc hasKey*(settings: Settings, key: string): bool {.inline.} =
  settings.data.hasKey(key)

proc `[]`*(settings: Settings, key: string): JsonNode {.inline.} =
  settings.data[key]

proc getOrDefault*(settings: Settings, key: string): JsonNode {.inline.} =
  settings.data.getOrDefault(key)

proc newCtxSettings*(): CtxSettings {.inline.} =
  # Ctretes a new context settings.
  CtxSettings(mimeDB: newMimetypes(), config: newTable[string, StringTableRef]())

proc newLocalSettings*(data: JsonNode): LocalSettings {.inline.} =
  ## Creates a new localSettings.
  result = LocalSettings(data: data)

proc newLocalSettings*(configPath: string): LocalSettings {.inline.} =
  ## Creates a new localSettings.
  result = LocalSettings(data: parseFile(configPath))

proc newSettings*(address = "", port = Port(8080), debug = true, reusePort = true,
                  staticDirs: openArray[string] = ["static"], secretKey = randomString(8),
                  appName = ""): Settings {.inline.} =
  ## Creates a new settings.
  if secretKey.len == 0:
    raise newException(EmptySecretKeyError, "Secret key can't be empty!")

  result = Settings(address: address, port: port, debug: debug, reusePort: reusePort,
                    staticDirs: @staticDirs, appName: appName,
                    data: %* {"secretKey": secretKey})


proc newSettings*(data: JsonNode, address = "", port = Port(8080), debug = true, reusePort = true,
                  staticDirs: openArray[string] = ["static"],
                  appName = ""): Settings {.inline.} =
  ## Creates a new settings.
  result = Settings(address: address, port: port, debug: debug, reusePort: reusePort,
                    staticDirs: @staticDirs, appName: appName,
                    data: data)

proc newSettings*(configPath: string, address = "", port = Port(8080), debug = true, reusePort = true,
                  staticDirs: openArray[string] = ["static"],
                  appName = ""): Settings {.inline.} =
  ## Creates a new settings.
  # make sure reserved keys must appear in settings
  result = Settings(address: address, port: port, debug: debug, reusePort: reusePort,
                    staticDirs: @staticDirs, appName: appName,
                    data: parseFile(configPath))
