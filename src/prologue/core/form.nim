# Copyright 2020 Zeshen Xing
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


import std/[strtabs, strutils, strformat, parseutils, tables]
from std/uri import decodeQuery

import ./httpcore/httplogue
from ./types import FormPart, initFormPart, `[]=`
import ./request


func parseFormPart*(body, contentType: string): FormPart =
  ## Parses form part of the body of the request.
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
    inc(pos, 4)
    tail = data[pos ..< ^2] # 2 because of protocol newline after content disposition body

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
          result.data[name] = (newStringTable(mode = modeCaseSensitive), "")
        of "filename":
          result.data[name].params["filename"] = move(formValue)
        of "filename*":
          result.data[name].params["filenameStar"] = move(formValue)
        else:
          discard
        inc(times)
        if times >= 3:
          break

    result.data[name].body = tail

func parseFormParams*(request: var Request, contentType: string) =
  ## Parses get or post or query parameters.
  if "form-urlencoded" in contentType:
    request.formParams = initFormPart()
    if request.reqMethod == HttpPost:
      for (key, value) in decodeQuery(request.body):
        # formPrams and postParams for secret event
        request.formParams[key] = value
        request.postParams[key] = value
  elif "multipart/form-data" in contentType and "boundary" in contentType:
    request.formParams = parseFormPart(request.body, contentType)

  # /student?name=simon&age=sixteen
  # query -> name=simon&age=sixteen

  for (key, value) in decodeQuery(request.query):
    request.queryParams[key] = value
