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

import std/strformat

import ../core/application


proc mockingMiddleware*(): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    ctx.handled = true
    await switch(ctx)

proc mockApp*(app: Prologue) {.inline.} =
  ## Adds mocking middleware to global middlewares.
  app.middlewares.add mockingMiddleware()

func debugResponse*(ctx: Context) {.inline.} =
  debugEcho &"{ctx.response.code} {ctx.response.headers} \n {ctx.response.body}"

proc runOnce*(app: Prologue, request: Request): Context =
  ## Starts an Application.
  new result
  init(result, request, initResponse(HttpVer11, Http200), app.gScope)
  waitFor handleContext(app, result)

proc runOnce*(app: Prologue, ctx: Context) =
  ## Starts an Application.
  waitFor handleContext(app, ctx)
