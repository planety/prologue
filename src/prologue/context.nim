import strtabs, asyncdispatch

import request, response, pages, constants

# TODO may add app instance
type
  Context* = ref object
    request*: Request
    response*: Response

proc newContext*(request: Request, response: Response, cookies = newStringTable()): Context {.inline.} =
  Context(request: request, response: response)

proc handle*(ctx: Context) {.async, inline.} =
  await ctx.request.respond(ctx.response)

proc defaultHandler*(ctx: Context) {.async.} =
  let response = error404(body = errorPage("404 Not Found!", PrologueVersion))
  await ctx.request.respond(response)
