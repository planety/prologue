import strutils


type
  BaseType* = int | float | bool | string
  SecretKey* = distinct string
  SecretUrl* = distinct string

proc tryParseInt(value: string): int {.inline.} =
  try:
    result = parseInt(value)
  except ValueError:
    discard

proc tryParseFloat(value: string): float {.inline.} =
  try:
    result = parseFloat(value)
  except ValueError:
    discard

proc tryParseBool(value: string): bool {.inline.} =
  try:
    result = parseBool(value)
  except ValueError:
    discard

proc parseValue*[T: BaseType](value: string, default: T): T {.inline.} =
  if value == "":
    return default

  when T is int:
    result = tryParseInt(value)
  elif T is float:
    result = tryParseFloat(value)
  elif T is bool:
    result = tryParseBool(value)
  elif T is string:
    result = value

proc `$`*(secretKey: SecretKey): string =
  "SecretKey(********)"
