import asyncdispatch

from ../core/middlewaresbase import switch
from ../core/context import Context, HandlerAsync
from ../auth/httpauth import basicAuth, unauthenticate, VerifyHandler


proc basicAuthMiddleware*(realm: string, verifyHandler: VerifyHandler, charset = "UTF-8"): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    discard
