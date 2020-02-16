import strutils, strtabs, parseutils


type
  BadSecretKeyError* = object of Exception
  BaseType* = int | float | bool | string
  SecretKey* = distinct string
  SecretUrl* = distinct string

  SameSite* = enum
    None, Lax, Strict

  Session* = ref object
    data: StringTableRef
    newCreated*: bool
    modified*: bool
    accessed*: bool

proc tryParseInt(value: sink string, default: int): int {.inline.} =
  try:
    result = parseInt(value)
  except ValueError:
    result = default

proc tryParseFloat(value: sink string, default: float): float {.inline.} =
  try:
    result = parseFloat(value)
  except ValueError:
    result = default

proc tryParseBool(value: sink string, default: bool): bool {.inline.} =
  try:
    result = parseBool(value)
  except ValueError:
    result = default

proc parseValue*[T: BaseType](value: sink string, default: T): T {.inline.} =
  if value == "":
    return default

  when T is int:
    result = tryParseInt(value, default)
  elif T is float:
    result = tryParseFloat(value, default)
  elif T is bool:
    result = tryParseBool(value, default)
  elif T is string:
    result = value

proc len*(secretKey: SecretKey): int =
  string(secretKey).len

proc `$`*(secretKey: SecretKey): string =
  ## Hide secretKey's value
  "SecretKey(********)"

proc initSession*(data: StringTableRef, newCreated = false, modified = false, accessed = false): Session =
  Session(data: data, modified: modified)

proc update*(session: Session) =
  session.accessed = true
  session.modified = true

proc `[]`*(session: Session, key: string): string =
  result = session.data[key]
  session.accessed = true

proc `[]=`*(session: Session, key, value: string): string =
  session.data[key] = value
  update(session)

proc len*(session: Session): int = 
  session.data.len

proc getOrDefault*(session: Session, key: string, default = ""): string =
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

proc `$`*(session: Session): string =
  $session.data

proc parseStringTable*(tabs: StringTableRef, s: string) {.inline.} =
  # """{username: flywind, password: root}"""
  # {:} 
  # make sure {':', ',', '}'} notin key or value
  if s.len <= 3:
    return
  var 
    pos = 0
    key, value: string
  assert(s[pos] == '{', "StringTable String starts with '{'")
  # ignore '{'
  inc(pos)
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

proc parseStringTable*(s: string): StringTableRef =
  result = newStringTable()
  parseStringTable(result, s)

proc loads*(session: Session, s: string) {.inline.} =
  session.data.parseStringTable(s)

proc dumps*(session: Session): string {.inline.} =
  $session
