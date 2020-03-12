import strutils, parseutils


proc isInt*(value: string): bool {.inline.} =
  var ignoreMe = 0
  result = parseInt(value, ignoreMe) == value.len

proc isNumeric*(value: string): bool {.inline.} =
  var ignoreMe = 0.0
  result = parseFloat(value, ignoreMe) == value.len

proc isBool*(value: string): bool {.inline.} =
  result = true
  try:
    discard parseBool(value)
  except ValueError:
    result = false
