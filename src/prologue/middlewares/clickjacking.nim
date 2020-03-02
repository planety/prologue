import asyncdispatch

from ../core/context import Context, HandlerAsync, setHeader
from ../core/middlewaresbase import switch


type
  XframeOption* = enum
    Deny = "deny", SameOrigin = "sameorigin"


# TODO all should in settings later[namely xFrameOption]
proc clickjackingMiddleWare*(xFrameOption = Deny): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    await switch(ctx)
    ctx.setHeader("X-Frame-Options", $xFrameOption)
