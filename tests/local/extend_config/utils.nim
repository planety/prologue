import parsetoml, json, sequtils


proc toRealJson*(value: TomlValueRef): JsonNode

proc toRealJson*(table: TomlTableRef): JsonNode =
  result = newJObject()
  for key, value in pairs(table):
    result[key] = value.toRealJson

proc toRealJson*(value: TomlValueRef): JsonNode =
  case value.kind
  of TomlValueKind.Int:
    %* value.intVal
  of TomlValueKind.Float:
    %* value.floatVal
  of TomlValueKind.Bool:
    %* value.boolVal
  of TomlValueKind.Datetime:
    %* $value.datetimeVal
  of TomlValueKind.Date:
    %* $value.dateVal
  of TomlValueKind.Time:
    %* $value.timeVal
  of TomlValueKind.String:
    %* value.stringVal
  of TomlValueKind.Array:
    if value.arrayVal.len == 0:
      %* []
    else:
      %* value.arrayVal.map(toRealJson)
  of TomlValueKind.Table:
    value.tableVal.toRealJson
  of TomlValueKind.None:
    %* "ERROR"
  