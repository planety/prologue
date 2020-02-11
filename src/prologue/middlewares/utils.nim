import asyncdispatch, httpcore
import logging, strtabs, strutils

import ../context, core


when not defined(production):
  import ../naiverequest


proc doNothingClosureMiddleware*(): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    await switch(ctx)

proc loggingMiddleware*(appName = "Starlight"): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    logging.info "logging->begin"
    logging.debug "============================"
    logging.debug appName
    logging.debug "from logging middleware"
    logging.debug "route: " & ctx.request.path
    logging.debug "headers: " & $ctx.request.headers
    logging.debug "============================"
    await switch(ctx)
    logging.info "logging->end"

proc debugRequestMiddleware*(appName = "Starlight"): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    logging.info "debug->begin"
    logging.debug "============================"
    logging.debug appName
    logging.debug "from debugRequestMiddleware"
    logging.debug "url: " & $ctx.request.url
    logging.debug "queryParams: " & $ctx.request.queryParams
    logging.debug "method: " & $ctx.request.reqMethod
    logging.debug "headers: " & $ctx.request.headers
    logging.debug "body: " & ctx.request.body
    logging.debug "============================"
    await switch(ctx)
    logging.info "debug->end"

proc stripPathMiddleware*(appName = "Starlight"): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    logging.info "strip->begin"
    logging.debug "============================"
    logging.debug appName
    logging.debug "from stripPathMiddleware"
    ctx.request.stripPath()
    logging.debug ctx.request.path
    logging.debug "============================"
    await switch(ctx)
    logging.info "strip->end"

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
