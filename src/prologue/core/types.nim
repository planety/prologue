import strutils, strtabs, parseutils


type
  BaseType* = int | float | bool | string
  SecretKey* = distinct string
  SecretUrl* = distinct string

  SameSite* = enum
    None, Lax, Strict

  Session* = object
    data: StringTableRef

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

proc `$`*(secretKey: SecretKey): string =
  ## Hide secretKey's value
  "SecretKey(********)"

proc `[]`*(session: Session, key: string): string =
  session.data[key]

proc `[]=`*(session: Session, key, value: string): string =
  session.data[key] = value

proc getOrDefault*(session: Session, key: string, default = ""): string =
  if session.data.hasKey(key):
    result = session.data[key]
  else:
    result = default

proc `$`*(session: Session): string =
  $session.data

proc parseStringTable*(s: string): StringTableRef =
  # """{username: flywind, password: root}"""
  # {:} 
  # make sure {':', ',', '}'} notin key or value
  result = newStringTable()
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
    result[key] = value
    if pos >= s.len:
      break
