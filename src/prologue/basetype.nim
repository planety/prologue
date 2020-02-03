import strutils


type
  BaseType* = int | float | bool | string


proc tryParseInt*(value: string): int =
  try:
    result = parseInt(value)
  except ValueError:
    discard

proc tryParseFloat*(value: string): float =
  try:
    result = parseFloat(value)
  except ValueError:
    discard

proc tryParseBool*(value: string): bool =
  try:
    result = parseBool(value)
  except ValueError:
    discard

proc parseValue*[T: BaseType](value: string, default: T): T =
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
