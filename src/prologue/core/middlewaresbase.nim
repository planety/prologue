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


import std/[asyncdispatch]

from ./context import HandlerAsync, Context, size, incSize, first, `first=`, 
                      middlewares, `middlewares=`, addMiddlewares, newContextFrom,
                      newContextTo

from ./route import findHandler


proc doNothingClosureMiddleware*(): HandlerAsync

type
  SubContext* = concept ctx
    ctx is Context


proc switch*(ctx: Context) {.async.} =
  ## Switch the control to the next handler.
  # TODO make middlewares checked
  if ctx.middlewares.len == 0:
    let
      handler = findHandler(ctx)
      next = handler.handler

    ctx.middlewares = handler.middlewares
    ctx.addMiddlewares next
    ctx.first = false

  incSize(ctx)

  if ctx.size <= ctx.middlewares.len.int8:
    let next = ctx.middlewares[ctx.size - 1]
    await next(ctx)
  elif ctx.first:
    let
      handler = findHandler(ctx)
      lastHandler = handler.handler

    ctx.addMiddlewares handler.middlewares
    ctx.addMiddlewares lastHandler
    ctx.first = false

    let next = ctx.middlewares[ctx.size - 1]
    await next(ctx)

proc doNothingClosureMiddleware*(): HandlerAsync =
  ## Don't do anything, just for placeholder.
  result = proc(ctx: Context) {.async.} =
    await switch(ctx)

import std/logging

template handleCtxError(ctx: SubContext) =
  try:
    await switch(ctx)
  except RouteError as e:
    ctx.response.code = Http404
    ctx.response.body.setLen(0)
    logging.debug e.msg
  except HttpError as e:
    # catch general http error
    logging.debug e.msg
  except AbortError as e:
    # catch abort error
    logging.debug e.msg
  except Exception as e:
    logging.error e.msg
    ctx.response.code = Http500
    ctx.response.body = e.msg
    ctx.response.setHeader("content-type", "text/plain; charset=UTF-8")

proc extendContextMiddleWare*[T: SubContext](ctxType: typedesc[T]): HandlerAsync {.deprecated.} =
  result = proc(ctx: Context) {.async.} =
    var userContext = new ctxType
    newContextFrom(userContext, ctx)
    handleCtxError(userContext)
    newContextTo(ctx, userContext)
