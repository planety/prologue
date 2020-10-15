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
import std/[strutils, strtabs, parseutils, tables, options]

import ./encode


const
  FlashPrefix = "_flash_"

type
  BadSecretKeyError* = object of CatchableError
  EmptySecretKeyError* = object of CatchableError
  BaseType* = int | float | bool | string
  SecretKey* = distinct string
  SecretUrl* = distinct string


  Session* = ref object
    data: StringTableRef
    newCreated*: bool
    modified*: bool
    accessed*: bool

  FlashLevel* = enum
    Info = "info"
    Warning = "warning"
    Error = "error"
    Fault = "fault"

  FormPart* = object
    data*: OrderedTableRef[string, tuple[params: StringTableRef, body: string]]


func initFormPart*(): FormPart =
  FormPart(data: newOrderedTable[string, (StringTableRef, string)]())

func `[]`*(formPart: FormPart, key: string): tuple[params: StringTableRef,
           body: string] {.inline.} =
  formPart.data[key]

proc `[]=`*(formPart: FormPart, key: string, body: string) {.inline.} =
  formPart.data[key] = (newStringTable(mode = modeCaseSensitive), body)

func tryParseInt(value: string, default: int): int {.inline.} =
  try:
    result = parseInt(value)
  except ValueError:
    result = default

func tryParseFloat(value: string, default: float): float {.inline.} =
  try:
    result = parseFloat(value)
  except ValueError:
    result = default

func tryParseBool(value: string, default: bool): bool {.inline.} =
  try:
    result = parseBool(value)
  except ValueError:
    result = default

func parseValue*[T: BaseType](value: string, default: T): T {.inline.} =
  if value.len == 0:
    return default

  when T is int:
    result = tryParseInt(value, default)
  elif T is float:
    result = tryParseFloat(value, default)
  elif T is bool:
    result = tryParseBool(value, default)
  elif T is string:
    result = value

func len*(secretKey: SecretKey): int {.inline.} =
  string(secretKey).len

func `$`*(secretKey: SecretKey): string {.inline.} =
  ## Hide secretKey's value
  "SecretKey(********)"

func newSession*(data: StringTableRef, newCreated = false, modified = false,
    accessed = false): Session {.inline.} =
  ## Initializes a new session.
  Session(data: data, newCreated: newCreated, modified: modified, accessed: accessed)

func update(session: var Session) {.inline.} =
  session.accessed = true
  session.modified = true

func `[]`*(session: var Session, key: string): string {.inline.} =
  ## Retrieves the value if `key` exists in `session`.
  result = session.data[key]
  session.accessed = true

func `[]=`*(session: var Session, key, value: string) {.inline.} =
  ## sets the (key, value) pair.
  session.data[key] = value
  update(session)

func len*(session: Session): int {.inline.} =
  ## Gets the size of `session`.
  session.data.len

iterator pairs*(session: Session): tuple[key, val: string] =
  session.accessed = true
  for (key, val) in session.data.pairs:
    yield (key, val)

func getOrDefault*(session: var Session, key: string, default = ""): string {.inline.} =
  ## Retrieves the value if `key` exists in `session`. Otherwise `default` will be returned.
  if session.data.hasKey(key):
    result = session.data[key]
  else:
    result = default
  session.accessed = true

func del*(session: var Session, key: string) {.inline.} =
  ## Deletes `key` from `session`.
  session.data.del(key)
  update(session)

func clear*(session: var Session) {.inline.} =
  ## Clears the data of `session`.
  session.data.clear(modeCaseSensitive)
  update(session)

func `$`*(session: Session): string {.inline.} =
  $session.data

func parseStringTable*(tabs: var StringTableRef, s: string) =
  # """{username: flywind, password: root}"""
  # {:}
  # TODO make sure {':', ',', '}'} notin key or value
  if s.len <= 3:
    return
  var
    pos = 0
    key, value: string

  # ignore '{'
  pos += skipWhile(s, {'{'})

  while true:
    pos += s.parseUntil(key, ':', pos)
    # ignore ':'
    inc(pos, 2)
    if pos >= s.len:
      break

    pos += s.parseUntil(value, {',', '}'}, pos)
    # ignore ',' or '}'
    inc(pos, 2)
    tabs[key] = value
    if pos >= s.len:
      break

proc loads*(session: var Session, s: string) {.inline.} =
  ## Loads session from strings.
  session.data = newStringTable(mode = modeCaseSensitive)
  session.data.parseStringTable(urlsafeBase64Decode(s))

proc dumps*(session: Session): string {.inline.} =
  ## Dumps session to strings.
  urlsafeBase64Encode($session)

func flash*(session: var Session, msgs: string, category = FlashLevel.Info) {.inline.} =
  session[FlashPrefix & $category] = msgs

func flash*(session: var Session, msgs: string, category: string) {.inline.} =
  session[FlashPrefix & category] = msgs

proc messages*(session: var Session): seq[string] =
  update(session)
  var delKeys: seq[string]
  for key, value in session.data:
    if key.startsWith(FlashPrefix):
      result.add value
      delKeys.add key

  for key in delKeys:
    session.data.del(key)

proc messagesWithCategory*(session: var Session): seq[(string, string)] =
  update(session)
  var delKeys: seq[string]
  for key, value in session.data:
    if key.startsWith(FlashPrefix):
      result.add (key[FlashPrefix.len .. ^1], value)
      delKeys.add key

  for key in delKeys:
    session.data.del(key)

func getMessage*(session: var Session, category: FlashLevel): Option[string] {.inline.} =
  update(session)
  let key = FlashPrefix & $category
  if session.data.hasKey(key):
    result = some(session.data[key])
    session.data.del(key)
  else:
    result = none(string)

func getMessage*(session: var Session, category: string): Option[string] {.inline.} =
  update(session)
  let key = FlashPrefix & category
  if session.data.hasKey(key):
    result = some(session.data[key])
    session.data.del(key)
  else:
    result = none(string)
