import logging

import request, context, httpcore, strtabs


proc loggingMiddleware*(ctx: Context): bool =
  logging.debug "============================"
  logging.debug "from logging middleware"
  logging.debug "route: " & ctx.request.path
  logging.debug "headers: " & $ctx.request.headers
  logging.debug "============================"
  return false

proc debugRequestMiddleware*(ctx: Context): bool =
  logging.debug "============================"
  logging.debug "from debugRequestMiddleware"
  logging.debug "url: " & $ctx.request.url
  logging.debug "queryParams: " & $ctx.request.queryParams
  logging.debug "methd: " & $ctx.request.reqMethod
  logging.debug "headers: " & $ctx.request.headers
  logging.debug "body: " & ctx.request.body
  logging.debug "============================"
  return false

proc stripPathMiddleware*(ctx: Context): bool =
  logging.debug "============================"
  logging.debug "from stripPathMiddleware"
  ctx.request.stripPath()
  logging.debug "============================"
  return false

proc httpRedirectMiddleWare*(ctx: Context): bool =
  case ctx.request.scheme
  of "http":
    setScheme(ctx.request, "https")
  of "ws":
    setScheme(ctx.request, "wss")
  else:
    return false
  ctx.response.status = Http307
  return true
