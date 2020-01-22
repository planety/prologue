import logging

import request, context, httpcore


proc loggingMiddleware*(ctx: Context) =
  logging.debug "============================"
  logging.debug "from logging middleware"
  logging.debug "route: " & ctx.request.path
  logging.debug "headers: " & $ctx.request.headers
  logging.debug "============================"

proc debugRequestMiddleware*(ctx: Context) =
  logging.debug "============================"
  logging.debug "from debugRequestMiddleware"
  logging.debug "route: " & ctx.request.path
  logging.debug "methd: " & $ctx.request.reqMethod
  logging.debug "headers: " & $ctx.request.headers
  logging.debug "body: " & ctx.request.body
  logging.debug "============================"
