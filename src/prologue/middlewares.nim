import logging, asyncdispatch

import request, context, httpcore, strtabs


proc start*(ctx: Context) {.async.} =
  ctx.size += 1
  if ctx.size <= ctx.length:
    let next = ctx.middlewares[ctx.size - 1]
    await next(ctx)

proc loggingMiddleware*(ctx: Context) {.async.} =
  echo "logging->begin"
  logging.debug "============================"
  logging.debug "from logging middleware"
  logging.debug "route: " & ctx.request.path
  logging.debug "headers: " & $ctx.request.headers
  logging.debug "============================"
  await start(ctx)
  echo "logging->end"

proc debugRequestMiddleware*(ctx: Context) {.async.} =
  echo "debug->begin"
  logging.debug "============================"
  logging.debug "from debugRequestMiddleware"
  logging.debug "url: " & $ctx.request.url
  logging.debug "queryParams: " & $ctx.request.queryParams
  logging.debug "method: " & $ctx.request.reqMethod
  logging.debug "headers: " & $ctx.request.headers
  logging.debug "body: " & ctx.request.body
  logging.debug "============================"
  await start(ctx)
  echo "debug->end"

proc stripPathMiddleware*(ctx: Context) {.async.} =
  echo "strip->begin"
  logging.debug "============================"
  logging.debug "from stripPathMiddleware"
  ctx.request.stripPath()
  logging.debug "============================"
  await start(ctx)
  echo "strip->end"

proc httpRedirectMiddleWare*(ctx: Context) {.async.} =
  case ctx.request.scheme
  of "http":
    setScheme(ctx.request, "https")
  of "ws":
    setScheme(ctx.request, "wss")
  else:
    return
  
  await start(ctx)
  ctx.response.status = Http307
  