import asyncdispatch

import sessionsbase

from ../../core/types import SecretKey, SameSite
from ../../core/cookies import setCookie
from ../../core/context import Context, HandlerAsync
import ../../signing/signer
import ../middlewaresbase


proc sessionMiddleware*(
  secretKey: SecretKey, 
  sessionName: string = "session", 
  maxAge: int = 14 * 24 * 60 * 60,  # 14 days, in seconds
  sameSite = Lax,
  httpsOnly = false): HandlerAsync =

  result = proc(ctx: Context) {.async.} =
    # TODO make sure {':', ',', '}'} notin key or value
    await switch(ctx)
  # setCookie(key, value: string, expires = "", domain = "", path = "",
  #                secure = false, httpOnly = false,
  #                sameSite = Lax)

  # setCookie*(response: var Response; key, value: string,
  #   expires: DateTime|Time, domain = "", path = "", secure = false,
  #       httpOnly = false, sameSite = Lax) 
