import strutils, os


template since*(version, body: untyped) {.dirty.} =
  ## limitation: can't be used to annotate a template (eg typetraits.get), would
  ## error: cannot attach a custom pragma.
  when (NimMajor, NimMinor) >= version:
    body

# TODO app add version
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

proc isStaticFile*(path: string, dirs: sink seq[string]): tuple[hasValue: bool,
    fileName, root: string] {.inline.} =
  let file = splitFile(path.strip(chars = {'/'}, trailing = false))

  for dir in dirs:
    if file.dir.startsWith(dir.strip(chars = {'/'},
        trailing = false)):
      return (true, file.name & file.ext, file.dir)

  return (false, "", "")
