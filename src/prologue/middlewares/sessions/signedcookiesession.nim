import asyncdispatch

import sessionsbase

from ../../core/types import SecretKey, SameSite, parseSession
from ../../core/context import Context, HandlerAsync, getCookie, setCookie
import ../../signing/signer 
from ../../core/middlewaresbase import switch


proc sessionMiddleware*(
  secretKey: SecretKey, 
  sessionName: string = "session", 
  salt = "prologue.signedcookiesession",
  sep = DefaultSep,
  keyDerivation = DefaultKeyDerivation,
  digestMethodType = DefaultDigestMethodType,
  maxAge: int = 14 * 24 * 60 * 60,  # 14 days, in seconds
  sameSite = Lax,
  httpsOnly = false
  ): HandlerAsync =

  let signer = initTimedSigner(secretKey, salt, sep, keyDerivation, digestMethodType)
  result = proc(ctx: Context) {.async.} =
    # TODO make sure {':', ',', '}'} notin key or value
    let 
      data = ctx.getCookie(sessionName)

    ctx.session.parseSession(signer.unsign(data))
    await switch(ctx)
  # setCookie(key, value: string, expires = "", domain = "", path = "",
  #                secure = false, httpOnly = false,
  #                sameSite = Lax)

  # setCookie*(response: var Response; key, value: string,
  #   expires: DateTime|Time, domain = "", path = "", secure = false,
  #       httpOnly = false, sameSite = Lax) 
