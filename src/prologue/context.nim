import strtabs, asyncdispatch, httpcore
import os
import mimetypes

import request, response, nativesettings

# TODO may add app instance
type
  Context* = ref object
    request*: Request
    response*: Response

proc newContext*(request: Request, response: Response, cookies = newStringTable()): Context {.inline.} =
  Context(request: request, response: response)

proc handle*(ctx: Context) {.async, inline.} =
  await ctx.request.respond(ctx.response)

# Static File Response
proc staticFileResponse*(ctx: Context, fileName, root: string, mimetype = "",
    download = false, charset = "UTF-8", headers = newHttpHeaders()): Response {.inline.} =
  let 
    status = Http200
  var mimetype = mimetype
  if mimetype == "":
    let ext = fileName.splitFile.ext
    mimetype = ctx.request.settings.mimeDB.getMimetype(ext)


  let f = open(fileName, fmRead)
  defer: f.close()
  result = initResponse(HttpVer11, status, headers, body = f.readAll())
