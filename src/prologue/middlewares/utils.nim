# Copyright 2020 ringabout
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

import std/[logging, strtabs, strutils, os]
import ../core/asyncbackend

from ../core/context import Context, HandlerAsync
from ../core/middlewaresbase import switch
import ../core/request
import ../core/httpcore/httplogue

template logInfo(msg: string) =
  {.cast(raises: []).}: logging.info(msg)

template logDebug(msg: string) =
  {.cast(raises: []).}: logging.debug(msg)


proc testMiddleware*(): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    logInfo "debug->begin"
    await switch(ctx)
    logInfo "debug->end"


proc loggingMiddleware*(appName = "Prologue"): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    logInfo "loggingMiddleware->begin"
    logDebug "============================"
    logDebug appName
    logDebug "route: " & ctx.request.path
    logDebug "headers: " & $ctx.request.headers
    logDebug "============================"
    logInfo "loggingMiddleware->end"
    await switch(ctx)

proc debugRequestMiddleware*(appName = "Prologue"): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    logInfo "debugRequestMiddleware->begin"
    logDebug "============================"
    logDebug appName
    logDebug "url: " & $ctx.request.url
    logDebug "queryParams: " & $ctx.request.queryParams
    logDebug "method: " & $ctx.request.reqMethod
    logDebug "headers: " & $ctx.request.headers
    logDebug "body: " & ctx.request.body
    logDebug "============================"
    logInfo "debugRequestMiddleware->end"
    await switch(ctx)

proc debugResponseMiddleware*(appName = "Prologue"): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    await switch(ctx)
    logInfo "debugResponseMiddleware->begin"
    logDebug "============================"
    logDebug appName
    logDebug "headers: " & $ctx.response.headers
    logDebug "body: " & ctx.response.body
    logDebug "============================"
    logInfo "debugResponseMiddleware->end"

proc stripPathMiddleware*(appName = "Prologue"): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    logInfo "stripPathMiddleware->begin"
    logDebug "============================"
    logDebug appName
    ctx.request.stripPath()
    logDebug ctx.request.path
    logDebug "============================"
    logInfo "stripPathMiddleware->end"
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

proc isStaticFile*(
  path: string, 
  dirs: openArray[string]
): tuple[hasValue: bool, filename, dir: string] =
  result = (false, "", "")
  var path = path.strip(chars = {'/'}, trailing = false)
  normalizePath(path)
  if not fileExists(path):
    return
  let file = splitFile(path)

  for dir in dirs:
    if dir.len == 0:
      continue
    if file.dir.startsWith(dir):
      return (true, file.name & file.ext, file.dir)
