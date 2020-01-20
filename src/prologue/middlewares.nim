import logging

import request, context, httpcore


proc loggingMiddleware*(ctx: Context) =
  logging.debug "============================"
  logging.debug "from logging middleware"
  logging.debug "route: " & ctx.request.path
  logging.debug "headers: " & $ctx.request.headers
  logging.debug "============================"
