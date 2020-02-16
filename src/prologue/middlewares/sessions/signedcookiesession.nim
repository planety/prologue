import asyncdispatch


from ../../core/types import SecretKey, SameSite, loads, dumps
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

    try:
      ctx.session.loads(signer.unsign(data, maxAge))
    except:
      # BadTimeSignature, SignatureExpired or ValueError
      # reset
      ctx.session.modified = true

    await switch(ctx)
    ctx.setCookie(sessionName, signer.sign(dumps(ctx.session)))
  # setCookie(key, value: string, expires = "", domain = "", path = "",
  #                secure = false, httpOnly = false,
  #                sameSite = Lax)

  # setCookie*(response: var Response; key, value: string,
  #   expires: DateTime|Time, domain = "", path = "", secure = false,
  #       httpOnly = false, sameSite = Lax) 
