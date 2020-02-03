import parseutils


# support str, int, float, path, ...
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


when isMainModule:
  assert parsePathParams("name:int") == ("name", "int")
  assert parsePathParams("name:") == ("name", "str")
  assert parsePathParams("name") == ("name", "str")
