import asyncdispatch
import json

from ../core/context import Context, HandlerAsync, setHeader, getSettings
from ../core/middlewaresbase import switch


proc clickjackingMiddleWare*(): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    await switch(ctx)
    var option = ctx.getSettings("X-Frame-Options").getStr
    if option != "deny" or option != "sameorigin":
      option = "deny"
    ctx.setHeader("X-Frame-Options", option)
