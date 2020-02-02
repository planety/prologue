import strutils

type
  FormPart* = object
    name*: string
    value*: string
    filename*: string
    filenamestar*: string

  MultiPartForm* = seq[FormPart]

  ParamsType* {.pure.} = enum
    Int, Float, String, Boolean, Path

  PathParams* = object
    paramsType*: ParamsType
    value*: string

  BaseType* = int | float | bool | string


proc initPathParams*(params, paramsType: string): PathParams =
  case paramsType
  of "int":
    result = PathParams(paramsType: Int, value: params)
  of "float":
    result = PathParams(paramsType: Float, value: params)
  of "bool":
    result = PathParams(paramsType: Boolean, value: params)
  of "str":
    result = PathParams(paramsType: String, value: params)
  of "path":
    result = PathParams(paramsType: Path, value: params)

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
