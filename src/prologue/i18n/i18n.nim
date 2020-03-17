import parsecfg, tables, strtabs, streams

when defined(windows) or defined(usestd):
  from ../naive/server import Prologue
else:
  from ../beast/server import Prologue


proc loadTranslate*(stream: Stream, fileName: string = "[stream]"): TableRef[
    string, StringTableRef] =
  var
    currentSection = ""
    p: CfgParser

  result = newTable[string, StringTableRef]()
  open(p, stream, fileName)
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

proc loadTranslate*(fileName: string): TableRef[string, StringTableRef] =
  let
    file = open(filename, fmRead)
    fileStream = newFileStream(file)
  defer: fileStream.close()
  result = fileStream.loadTranslate(filename)

proc loadTranslate*(app: Prologue, fileName: string) =
  let res = loadTranslate(filename)
  app.ctxSettings.config = res
