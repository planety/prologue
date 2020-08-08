# Copyright 2020 Zeshen Xing
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


import httpcore
import logging, strtabs, strutils


import ../core/dispatch
from ../core/context import Context, HandlerAsync
from ../core/middlewaresbase import switch
import ../core/request


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
    ctx.response.code = Http307
