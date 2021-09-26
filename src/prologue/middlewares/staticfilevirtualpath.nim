import std/[asyncdispatch, strutils, strformat, os, uri, sugar, logging]

import ../core/context, ../core/middlewaresbase, ../core/request
import ./utils


func normalizeStaticDir(dir: string): string =
  ## Normalizes the path of static directory.
  result = dir.strip(chars = {'/'}, trailing = false)
  normalizePath(result)

proc staticFileVirtualPathMiddleware*(staticDir: string,
    virtualPath: string): HandlerAsync =
  # whether request.path in the static path of settings.
  let staticDir = normalizeStaticDir(staticDir)
  let virtualPath = normalizeStaticDir(virtualPath)
  result = proc(ctx: Context) {.async.} =
    let virtualRequestFile = 
      ctx.request.path.decodeUrl.
      normalizeStaticDir().
      dup(removePrefix(_, virtualPath))
    let realFile = staticDir / virtualRequestFile
    let staticFileFlag =
      if staticDir.len != 0 and virtualPath.len != 0:
          isStaticFile(realFile, [staticDir])
      else:
        (false, "", "")

    if staticFileFlag.hasValue:
      logging.debug fmt"Reading virtual path {ctx.request.path.decodeUrl} from real path {realFile}"
      # serve static files
      await staticFileResponse(ctx, staticFileFlag.filename,
              staticFileFlag.dir,
              bufSize = ctx.gScope.settings.bufSize)
    else:
      await switch(ctx)