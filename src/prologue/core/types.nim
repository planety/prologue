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


import strutils, strtabs, parseutils, tables, base64


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

  FormPart* = object
    data*: OrderedTableRef[string, tuple[params: StringTableRef, body: string]]


func initFormPart*(): FormPart {.inline.} =
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

func initSession*(data: StringTableRef, newCreated = false, modified = false,
    accessed = false): Session {.inline.} =
  ## Initializes a new session.
  Session(data: data, modified: modified)

proc update*(session: Session) {.inline.} =
  session.accessed = true
  session.modified = true

proc `[]`*(session: Session, key: string): string {.inline.} =
  result = session.data[key]
  session.accessed = true

proc `[]=`*(session: Session, key, value: string) {.inline.} =
  session.data[key] = value
  update(session)

func len*(session: Session): int {.inline.} =
  session.data.len

iterator pairs*(session: Session): tuple[key, val: string] =
  for (key, val) in session.data.pairs:
    yield (key, val)

proc getOrDefault*(session: Session, key: string, default = ""): string {.inline.} =
  if session.data.hasKey(key):
    result = session.data[key]
  else:
    result = default
  session.accessed = true

proc del*(session: Session, key: string) {.inline.} =
  session.data.del(key)
  update(session)

proc clear*(session: Session) {.inline.} =
  session.data.clear(modeCaseSensitive)
  update(session)

func `$`*(session: Session): string {.inline.} =
  $session.data

proc parseStringTable*(tabs: StringTableRef, s: string) {.inline.} =
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

proc loads*(session: Session, s: string) {.inline.} =
  ## Loads session from strings.
  session.data = newStringTable(mode = modeCaseSensitive)
  session.data.parseStringTable(decode(s))

proc dumps*(session: Session): string {.inline.} =
  ## Dumps session to strings.
  encode($session)
