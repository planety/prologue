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

import std/[json, strutils, asyncdispatch]

from ../core/response import setHeader
from ../core/context import Context, HandlerAsync, getSettings
from ../core/middlewaresbase import switch


proc clickjackingMiddleWare*(): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    await switch(ctx)
    var option = ctx.getSettings("prologue").getOrDefault("X-Frame-Options").getStr.toLowerAscii

    if option != "deny" and option != "sameorigin":
      option = "deny"
    ctx.response.setHeader("X-Frame-Options", option)
