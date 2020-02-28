import asyncdispatch

from context import HandlerAsync, Context
from route import findHandler


proc doNothingClosureMiddleware*(): HandlerAsync


proc switch*(ctx: Context) {.async.} =
  ## TODO make middlewares checked
  if ctx.middlewares.len == 0:
    let
      handler = findHandler(ctx)
      next = handler.handler
    var
      middlewares = handler.middlewares

    # for findHandler in handler.excludeMiddlewares:
    #   let idx = middlewares.find(findHandler)
    #   if idx != -1:
    #     middlewares[idx] = doNothingClosureMiddleware()

    ctx.middlewares = middlewares & next
    ctx.first = false

  ctx.size += 1
  if ctx.size <= ctx.middlewares.len:
    let next = ctx.middlewares[ctx.size - 1]
    await next(ctx)
  elif ctx.first:
    let
      handler = findHandler(ctx)
      lastHandler = handler.handler
      middlewares = handler.middlewares
    ctx.middlewares = ctx.middlewares & middlewares & lastHandler
    ctx.first = false
    let next = ctx.middlewares[ctx.size - 1]
    await next(ctx)


proc doNothingClosureMiddleware*(): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    await switch(ctx)
