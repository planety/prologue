import strutils, os


template since*(version, body: untyped) {.dirty.} =
  ## limitation: can't be used to annotate a template (eg typetraits.get), would
  ## error: cannot attach a custom pragma.
  when (NimMajor, NimMinor) >= version:
    body

template sinceApi*(version, body: untyped) {.dirty.} =
  ## limitation: can't be used to annotate a template (eg typetraits.get), would
  ## error: cannot attach a custom pragma.
  when (NimMajor, NimMinor) >= version:
    body

template beforeApi*(version, body: untyped) {.dirty.} =
  ## limitation: can't be used to annotate a template (eg typetraits.get), would
  ## error: cannot attach a custom pragma.
  when (NimMajor, NimMinor) <= version:
    body

proc isStaticFile*(path: string, dirs: openArray[string]): tuple[hasValue: bool,
    filename, dir: string] {.inline.} =
  result = (false, "", "")
  var path = path.strip(chars = {'/'}, trailing = false)
  if not existsFile(path):
    return
  let file = splitFile(path)

  for dir in dirs:
    if dir.len == 0:
      continue
    if file.dir.startsWith(dir.strip(chars = {'/'},
        trailing = false)):
      return (true, file.name & file.ext, file.dir)
