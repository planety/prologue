import strtabs, asyncdispatch

import request, response

# TODO may add app instance
type
  Context* = ref object
    request*: Request
    response*: Response

proc newContext*(request: Request, response: Response, cookies = newStringTable()): Context {.inline.} =
  Context(request: request, response: response)

proc handle*(ctx: Context) {.async, inline.} =
  await ctx.request.respond(ctx.response)
