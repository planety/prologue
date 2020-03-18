import httpcore
import strtabs, strutils, strformat, parseutils, tables

from cgi import decodeData

from types import FormPart, initFormPart, `[]=`


when defined(windows) or defined(usestd):
  import ../naive/request
else:
  import ../beast/request


proc parseFormPart*(body, contentType: string): FormPart {.inline.} =
  # parse form
  let
    sep = contentType[contentType.rfind("boundary") + 9 .. ^1]
    startSep = fmt"--{sep}"
    endSep = fmt"--{sep}--"
    startPos = find(body, startSep)
    endPos = rfind(body, endSep)
    formData = body[startPos ..< endPos]
    formDataSeq = formData.split(startSep & "\c\L")

  result = initFormPart()

  for data in formDataSeq:
    if data.len == 0:
      continue

    var
      pos = 0
      head, tail: string
      name: string
      times = 0
      tok = ""
      formKey, formValue: string

    pos += parseUntil(data, head, "\c\L\c\L")
    pos += 4
    tail = data[pos ..< ^1]

    if not head.startsWith("Content-Disposition"):
      break

    for line in head.splitLines:
      let header = line.parseHeader
      if header.key != "Content-Disposition":
        result.data[name].params[header.key] = header.value[0]
        continue
      pos = 0
      let
        content = header.value[0]
        length = content.len
      pos += parseUntil(content, tok, ';', pos)

      while pos < length:
        pos += skipWhile(content, {';', ' '}, pos)
        pos += parseUntil(content, formKey, '=', pos)
        pos += skipWhile(content, {'=', '\"'}, pos)
        pos += parseUntil(content, formValue, '\"', pos)
        pos += skipWhile(content, {'\"'}, pos)

        case formKey
        of "name":
          name = move(formValue)
          result.data[name] = (newStringTable(), "")
        of "filename":
          result.data[name].params["filename"] = move(formValue)
        of "filename*":
          result.data[name].params["filenameStar"] = move(formValue)
        else:
          discard
        times += 1
        if times >= 3:
          break

    result.data[name].body = tail

proc parseFormParams*(request: var Request, contentType: string) =
  # get or post forms params
  if "form-urlencoded" in contentType:
    request.formParams = initFormPart()
    case request.reqMethod
    of HttpPost:
      for (key, value) in decodeData(request.body):
        # formPrams and postParams for secret event
        request.formParams[key] = value
        request.postParams[key] = value
    else:
      discard

  elif "multipart/form-data" in contentType and "boundary" in contentType:
    request.formParams = parseFormPart(request.body, contentType)

  # /student?name=simon&age=sixteen
  # query -> name=simon&age=sixteen
  for (key, value) in decodeData(request.query):
    request.queryParams[key] = value
