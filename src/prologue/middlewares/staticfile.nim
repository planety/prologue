import std/[asyncdispatch, strutils, os, uri]

import ../core/context, ../core/middlewaresbase, ../core/request
import ./utils

func normalizedStaticDirs(dirs: openArray[string]): seq[string] =
  ## Normalizes the path of static directories.
  result = newSeqOfCap[string](dirs.len)
  for item in dirs:
    let dir = item.strip(chars = {'/'}, trailing = false)
    if dir.len != 0:
      result.add dir
    normalizePath(result[^1])

proc staticFileMiddleware*(staticDirs: varargs[string]): HandlerAsync =
  ## A middleware that serves files from the directories `specified` in `staticDirs`
  ## if request.path matches the path to a file in one of the directories in `staticDirs`.
  ## The paths in `staticDirs` are interpreted as relative to the binary.
  let staticDirs = normalizedStaticDirs(staticDirs)
  result = proc(ctx: Context) {.async.} =
    let staticFileFlag = 
      if staticDirs.len != 0:
        isStaticFile(ctx.request.path.decodeUrl, staticDirs)
      else:
        (false, "", "")

    if staticFileFlag.hasValue:
      # serve static files
      await staticFileResponse(ctx, staticFileFlag.filename,
              staticFileFlag.dir,
              bufSize = ctx.gScope.settings.bufSize)
    else:
      await switch(ctx)

proc redirectTo*(
  dest: string, mimetype = "",
  downloadName = "", charset = "utf-8"
): HandlerAsync =
  var dest = dest.strip(trailing = false, chars = {'/'})
  normalizePath(dest)
  let res = splitFile(dest)
  let dir = res.dir
  let file = res.name & res.ext
  result = proc(ctx: Context) {.async.} =
    await staticFileResponse(ctx, file, dir, mimetype,
          downloadName, charset,
          ctx.gScope.settings.bufSize)
