import ./dispatch
from ./context import HandlerAsync, Context, size, incSize, first, `first=`
from ./route import findHandler


proc doNothingClosureMiddleware*(): HandlerAsync


proc switch*(ctx: Context) {.async.} =
  ## TODO make middlewares checked
  if ctx.middlewares.len == 0:
    let
      handler = findHandler(ctx)
      next = handler.handler
    var
      middlewares = handler.middlewares

    ctx.middlewares = middlewares & next
    ctx.first = false

  incSize(ctx)
  if ctx.size <= ctx.middlewares.len:
    let next = ctx.middlewares[ctx.size - 1]
    await next(ctx)
  elif ctx.first:
    let
      handler = findHandler(ctx)
      lastHandler = handler.handler
      middlewares = handler.middlewares
    ctx.localSettings = handler.settings
    ctx.middlewares.add middlewares & lastHandler
    ctx.first = false
    let next = ctx.middlewares[ctx.size - 1]
    await next(ctx)

proc doNothingClosureMiddleware*(): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    await switch(ctx)
