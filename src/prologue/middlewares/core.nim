import asyncdispatch

import ../context, ../route



proc switch*(ctx: Context) {.async.} =
  if ctx.middlewares.len == 0:
    let
      handler = findHandler(ctx)
      next = handler.handler
      middlewares = handler.middlewares
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