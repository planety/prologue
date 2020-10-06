import std/[strutils, parseutils]


func isInt*(value: string): bool {.inline.} =
  if value.len == 0:
    return false
  var ignoreMe = 0
  result = parseInt(value, ignoreMe) == value.len

func isNumeric*(value: string): bool {.inline.} =
  if value.len == 0:
    return false
  var ignoreMe = 0.0
  result = parseFloat(value, ignoreMe) == value.len

func isBool*(value: string): bool {.inline.} =
  result = true
  try:
    discard parseBool(value)
  except ValueError:
    result = false
