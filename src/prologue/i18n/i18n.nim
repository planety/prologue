import parsecfg, tables, strtabs, streams


from ../core/application import Prologue
from ../core/context import Context


type
  Translator* = object
    language*: string
    ctx*: Context


proc loadTranslate*(stream: Stream, filename: string = "[stream]"): TableRef[
    string, StringTableRef] =
  var
    currentSection = ""
    p: CfgParser

  result = newTable[string, StringTableRef]()
  open(p, stream, filename)
  defer: p.close()
  while true:
    var e = p.next
    case e.kind
    of cfgEof:
      break
    of cfgSectionStart:
      currentSection = e.section
    of {cfgKeyValuePair, cfgOption}:
      var t = newStringTable()
      if result.hasKey(currentSection):
        t = result[currentSection]
      t[e.key] = e.value
      result[currentSection] = t
    of cfgError:
      break

proc loadTranslate*(filename: string): TableRef[string, StringTableRef] {.inline.} =
  let
    file = open(filename, fmRead)
    fileStream = newFileStream(file)
  defer: fileStream.close()
  result = fileStream.loadTranslate(filename)

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
  let config = ctx.gScope.ctxSettings.config
  if not config.hasKey(text):
    return text
  let trans = config[text]
  if not trans.hasKey(language):
    return text
  return trans[language]

proc Tr*(ctx: Context, text: string, language: string): string {.inline.} =
  ctx.translate(text, language)
