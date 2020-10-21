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


import std/[parsecfg, tables, strtabs, streams]

from ../core/application import Prologue
from ../core/context import Context, gScope


type
  Translator* = object
    language*: string
    ctx*: Context


proc loadTranslate*(
  stream: Stream,
  filename = "[stream]"
): TableRef[string, StringTableRef] =
  var
    currentSection = ""
    p: CfgParser

  result = newTable[string, StringTableRef]()
  open(p, stream, filename)

  while true:
    var e = p.next
    case e.kind
    of cfgEof:
      break
    of cfgSectionStart:
      currentSection = e.section
    of {cfgKeyValuePair, cfgOption}:
      var t = newStringTable(mode = modeStyleInsensitive)
      if result.hasKey(currentSection):
        t = result[currentSection]
      t[e.key] = e.value
      result[currentSection] = t
    of cfgError:
      break
  p.close()

proc loadTranslate*(filename: string): TableRef[string, StringTableRef] {.inline.} =
  let
    file = open(filename, fmRead)
    fileStream = newFileStream(file)
  result = fileStream.loadTranslate(filename)
  fileStream.close()

proc loadTranslate*(app: Prologue, filename: string) {.inline.} =
  let res = loadTranslate(filename)
  app.gScope.ctxSettings.config = res

proc setLanguage*(ctx: Context, language: string): Translator {.inline.} =
  Translator(ctx: ctx, language: language)

proc translate*(t: Translator, text: string): string {.inline.} =
  let config = t.ctx.gScope.ctxSettings.config
  if not config.hasKey(text):
    return text
  let trans = config[text]
  if not trans.hasKey(t.language):
    return text
  return trans[t.language]

proc Tr*(t: Translator, text: string): string {.inline.} =
  t.translate(text)

proc translate*(ctx: Context, text: string, language: string): string {.inline.} =
  ## Translates text by `language`.
  let config = ctx.gScope.ctxSettings.config
  if not config.hasKey(text):
    return text
  let trans = config[text]
  if not trans.hasKey(language):
    return text
  return trans[language]

proc Tr*(ctx: Context, text: string, language: string): string {.inline.} =
  ## Helper function for ``translate``.
  ctx.translate(text, language)
