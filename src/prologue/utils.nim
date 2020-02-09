import parseutils, strutils


# support str, int, slug, uuid ...
proc parsePathParams*(s: string): (string, string) =
  var
    pos = 0
    params = ""
    paramsType = "str"
  pos += s.parseUntil(params, ":", pos)
  inc(pos)
  if pos < s.len:
    # ignore :
    paramsType = s[pos ..< s.len]
  result = (params, paramsType)

proc isInt(params: string): bool =
  for c in params:
    if c notin Digits:
      return false
  return true

proc checkPathParams*(params, paramsType: string): bool =
  case paramsType
  of "str":
    result = true
  of "int":
    result = isInt(params)
  else:
    discard


when isMainModule:
  assert parsePathParams("name:int") == ("name", "int")
  assert parsePathParams("name:") == ("name", "str")
  assert parsePathParams("name") == ("name", "str")
