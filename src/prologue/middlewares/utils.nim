import asyncdispatch, httpcore
import logging, strtabs, strutils

from ../core/context import Context, HandlerAsync
from ../core/middlewaresbase import switch


when defined(windows) or defined(usestd):
  import ../naive/request
else:
  import ../beast/request


proc loggingMiddleware*(appName = "Starlight"): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    logging.info "loggingMiddleware->begin"
    logging.debug "============================"
    logging.debug appName
    logging.debug "route: " & ctx.request.path
    logging.debug "headers: " & $ctx.request.headers
    logging.debug "============================"
    logging.info "loggingMiddleware->end"
    await switch(ctx)

proc debugRequestMiddleware*(appName = "Starlight"): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    logging.info "debugRequestMiddleware->begin"
    logging.debug "============================"
    logging.debug appName
    logging.debug "url: " & $ctx.request.url
    logging.debug "queryParams: " & $ctx.request.queryParams
    logging.debug "method: " & $ctx.request.reqMethod
    logging.debug "headers: " & $ctx.request.headers
    logging.debug "body: " & ctx.request.body
    logging.debug "============================"
    logging.info "debugRequestMiddleware->end"
    await switch(ctx)

proc debugResponseMiddleware*(appName = "Starlight"): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    await switch(ctx)
    logging.info "debugResponseMiddleware->begin"
    logging.debug "============================"
    logging.debug appName
    logging.debug "headers: " & $ctx.response.headers
    logging.debug "body: " & ctx.response.body
    logging.debug "============================"
    logging.info "debugResponseMiddleware->end"

proc stripPathMiddleware*(appName = "Starlight"): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    logging.info "stripPathMiddleware->begin"
    logging.debug "============================"
    logging.debug appName
    ctx.request.stripPath()
    logging.debug ctx.request.path
    logging.debug "============================"
    logging.info "stripPathMiddleware->end"
    await switch(ctx)

proc httpRedirectMiddleWare*(): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    case ctx.request.scheme
    of "http":
      setScheme(ctx.request, "https")
    of "ws":
      setScheme(ctx.request, "wss")
    else:
      return
    await switch(ctx)
    ctx.response.status = Http307
