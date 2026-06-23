# Copyright 2020 ringabout
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


import std/[mimetypes, json, tables, strtabs]
from std/nativesockets import Port
from std/net import Socket

from ./types import SecretKey, EmptySecretKeyError, len
from ./urandom import randomString


type
  Settings* = ref object     ## Global settings for all handlers.
    address*: string         ## The address of socket.
    port*: Port              ## The port of socket.
    listener*: Socket        ## listening socket to use (nil to auto create)
    debug*: bool             ## Debug mode(true is yes).
    reusePort*: bool         ## Use socket port in multiple times.
    bufSize*: int            ## Buffer size of sending static files.
    data: JsonNode           ## Data which carries user defined settings.

  CtxSettings* = ref object ## Context settings.
    mimeDB*: MimeDB
    config*: TableRef[string, StringTableRef]


func hasKey*(settings: Settings, key: string): bool {.inline.} =
  ## Returns true if `key` exists in `settings.data`.
  settings.data.hasKey(key)

func `[]`*(settings: Settings, key: string): JsonNode {.inline.} =
  ## Retrieves the value for `key` from `settings.data`.
  ## Raises `KeyError` if `key` is not present.
  settings.data[key]

func getOrDefault*(settings: Settings, key: string): JsonNode {.inline.} =
  ## Returns the value for `key` from `settings.data`, or `nil` if not present.
  settings.data.getOrDefault(key)

func newCtxSettings*(): CtxSettings =
  ## Creates a new `CtxSettings` with default MIME database and empty config.
  CtxSettings(mimeDB: newMimetypes(), config: newTable[string, StringTableRef]())

func newSettings*(
  address = "",
  port = Port(8080),
  debug = true,
  reusePort = true,
  secretKey = randomString(8),
  appName = "",
  bufSize = 40960,
  data: JsonNode = nil,
  listener: Socket = nil
): Settings =
  ## Creates a new `Settings` with the given parameters.
  ##
  ## When `data` is provided, any existing `"prologue"` key inside it is
  ## preserved — only `secretKey` and `appName` are merged in. This allows
  ## passing custom settings like `maxBody` via `data`:
  ##
  ## .. code-block:: nim
  ##   let settings = newSettings(
  ##     data = %* {"prologue": {"maxBody": 1_000}},
  ##     secretKey = "my-secret"
  ##   )
  ##
  ## When `data` is `nil`, a default JSON tree is created containing only
  ## `secretKey` and `appName`.
  if secretKey.len == 0:
    raise newException(EmptySecretKeyError, "Secret key can't be empty!")

  if data == nil:
    result = Settings(address: address, port: port, listener: listener,
                      debug: debug, reusePort: reusePort, bufSize: bufSize,
                      data: %* {"prologue": {"secretKey": secretKey,
                          "appName": appName}})
  else:
    var data = data
    if not data.hasKey("prologue"):
      data["prologue"] = %* {"secretKey": secretKey, "appName": appName}
    else:
      data["prologue"]["secretKey"] = % secretKey
      data["prologue"]["appName"] = % appName

    result = Settings(address: address, port: port, listener: listener,
                  debug: debug, reusePort: reusePort, bufSize: bufSize,
                  data: data)

func newSettingsFromJsonNode*(settings: var Settings, data: JsonNode) {.inline.} =
  ## Populates `settings` fields from `data`. The `"prologue"` key is required
  ## and must include `secretKey`. Standard fields (`address`, `port`, `debug`,
  ## `reusePort`, `bufSize`) are read from `"prologue"` if present; the full
  ## `data` tree is stored in `settings.data` for custom keys.
  if not data.hasKey("prologue"):
    raise newException(KeyError, "Key `prologue` must be present in the config file!")

  let logueSettings = data["prologue"]

  if not logueSettings.hasKey("secretKey") or logueSettings["secretKey"].getStr.len == 0:
    raise newException(EmptySecretKeyError, "Secret key can't be empty!")

  settings.address = logueSettings.getOrDefault("address").getStr
  settings.port = Port(logueSettings.getOrDefault("port").getInt(8080))
  settings.reusePort = logueSettings.getOrDefault("reusePort").getBool(true)
  settings.debug = logueSettings.getOrDefault("debug").getBool(true)
  settings.bufSize = logueSettings.getOrDefault("bufSize").getInt(40960)
  settings.data = data

func loadSettings*(
  data: JsonNode
): Settings =
  ## Creates a `Settings` from a `JsonNode`. The `"prologue"` key must
  ## contain at least `secretKey`. All other keys (e.g. `maxBody`) are
  ## preserved and accessible via `settings["prologue"]`.
  new result
  newSettingsFromJsonNode(result, data)

proc loadSettings*(
  configPath: string
): Settings =
  ## Creates a `Settings` by reading and parsing the JSON file at
  ## `configPath`. The file must contain a `"prologue"` key with
  ## `secretKey`.
  new result
  newSettingsFromJsonNode(result, parseFile(configPath))
