import strutils, strtabs, parseutils, tables


type
  BadSecretKeyError* = object of ValueError
  EmptySecretKeyError* = object of ValueError
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

  FormPart* = object
    data*: OrderedTableRef[string, tuple[params: StringTableRef, body: string]]


proc initFormPart*(): FormPart {.inline.} =
  FormPart(data: newOrderedTable[string, (StringTableRef, string)]())

proc `[]`*(formPart: FormPart, key: string): tuple[params: StringTableRef,
    body: string] {.inline.} =
  formPart.data[key]

proc `[]=`*(formPart: FormPart, key: string, body: string) {.inline.} =
  formPart.data[key] = (newStringTable(), body)

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

proc parseValue*[T: BaseType](value: string, default: T): T {.inline.} =
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

proc len*(secretKey: SecretKey): int {.inline.} =
  string(secretKey).len

proc `$`*(secretKey: SecretKey): string {.inline.} =
  ## Hide secretKey's value
  "SecretKey(********)"

proc initSession*(data: StringTableRef, newCreated = false, modified = false,
    accessed = false): Session {.inline.} =
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

proc len*(session: Session): int {.inline.} =
  session.data.len

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

proc `$`*(session: Session): string {.inline.} =
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

proc parseStringTable*(s: string): StringTableRef {.inline.} =
  result = newStringTable()
  parseStringTable(result, s)

proc loads*(session: Session, s: string) {.inline.} =
  session.data.parseStringTable(s)

proc dumps*(session: Session): string {.inline.} =
  $session
