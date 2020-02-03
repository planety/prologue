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
