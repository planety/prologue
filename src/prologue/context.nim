import strtabs, asyncdispatch, macros, tables

import request, response, pages, constants, base

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

macro getPathParams*(key: string): PathParams =
  var ctx = ident"ctx"

  result = quote do:
    `ctx`.request.pathParams.getOrDefault(`key`)

macro getPathParams*[T: BaseType](key: string, keyType: typedesc[T]): T =
  var ctx = ident"ctx"

  result = quote do:
    let pathParams = `ctx`.request.pathParams.getOrDefault(`key`)
    parseValue(pathParams.value, `keyType`)
