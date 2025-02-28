import std/[strutils, tables, strformat]

type
  MediaType* = object
    mainType*: string
    subType*: string
    parameters*: Table[string, string]

proc parseContentType*(headerValue: string): MediaType =
  ## Parses a Content-Type header according to RFC 7230, RFC 2045, and RFC 2046.
  ## Returns a MediaType object containing the main type, sub type, and parameters.
  result = MediaType(parameters: initTable[string, string]())
  var
    i = 0
    headerLen = headerValue.len

  while i < headerLen and headerValue[i] in Whitespace:
    inc i

  # media type
  let mediaTypeStart = i
  while i < headerLen and headerValue[i] notin {';', ' ', '\t'}:
    inc i

  let mediaType = headerValue[mediaTypeStart..<i].strip()
  let typeParts = mediaType.split('/')

  if typeParts.len != 2:
    raise newException(ValueError, &"Invalid media type: {mediaType}")

  result.mainType = typeParts[0].toLowerAscii
  result.subType = typeParts[1].toLowerAscii

  while i < headerLen and headerValue[i] in Whitespace:
    inc i

  # params
  while i < headerLen and headerValue[i] == ';':
    inc i

    while i < headerLen and headerValue[i] in Whitespace:
      inc i

    # param name
    let paramNameStart = i
    while i < headerLen and headerValue[i] notin {'=', ';', ' ', '\t'}:
      inc i

    if i >= headerLen or headerValue[i] != '=':
      # this is a malformed parameter - skip it
      while i < headerLen and headerValue[i] != ';':
        inc i
      continue

    let paramName = headerValue[paramNameStart..<i].strip().toLowerAscii()
    inc i

    while i < headerLen and headerValue[i] in Whitespace:
      inc i

    # param value
    var
      paramValue: string
      foundClosingQuote = false

    if i < headerLen and headerValue[i] == '"':
      # quoted value
      inc i
      let valueStart = i

      while i < headerLen:
        if headerValue[i] == '\\' and i + 1 < headerLen and headerValue[i + 1] == '"':
          inc i, 2
        elif headerValue[i] == '"':
          paramValue = headerValue[valueStart..<i]
          inc i
          foundClosingQuote = true
          break
        else:
          inc i

      if not foundClosingQuote:
        paramValue = headerValue[valueStart..<headerLen]
    else:
      # unquoted value
      let valueStart = i
      while i < headerLen and headerValue[i] notin {';', ' ', '\t'}:
        inc i

      paramValue = headerValue[valueStart..<i]

    result.parameters[paramName] = paramValue

    while i < headerLen and headerValue[i] in Whitespace:
      inc i

proc `$`*(mediaType: MediaType): string =
  ## Convert MediaType to string representation
  result = mediaType.mainType & "/" & mediaType.subType

  for name, value in mediaType.parameters:
    var needsQuotes = false
    for c in value:
      # valid token characters as per RFC 7230 section 3.2.6
      if not (c in {'a'..'z', 'A'..'Z', '0'..'9',
                    '!', '#', '$', '%', '&', '\'', '*', '+', '-', '.', '^', '_', '`', '|', '~'}):
        needsQuotes = true
        break

    if needsQuotes:
      result.add(&"; {name}=\"{value}\"")
    else:
      result.add(&"; {name}={value}")
