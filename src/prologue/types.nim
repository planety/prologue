import strutils


type
  BaseType* = int | float | bool | string
  SecretKey* = distinct string
  SecretUrl* = distinct string

proc tryParseInt(value: string, default: int): int {.inline.} =
  try:
    result = parseInt(value)
  except ValueError:
    result = default

proc tryParseFloat(value: string, default: float): float {.inline.} =
  try:
    result = parseFloat(value)
  except ValueError:
    result = default

proc tryParseBool(value: string, default: bool): bool {.inline.} =
  try:
    result = parseBool(value)
  except ValueError:
    result = default

proc parseValue*[T: BaseType](value: string, default: T): T {.inline.} =
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
