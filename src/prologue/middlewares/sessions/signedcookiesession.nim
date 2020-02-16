import asyncdispatch, options


from ../../core/types import BadSecretKeyError, SecretKey, SameSite, loads, dumps, len
from ../../core/context import Context, HandlerAsync, getCookie, setCookie,
    deleteCookie, addHeader
import ../../signing/signer
from ../../core/middlewaresbase import switch




proc sessionMiddleware*(
  secretKey: SecretKey,
  sessionName: string = "session",
  salt = "prologue.signedcookiesession",
  sep = DefaultSep,
  keyDerivation = DefaultKeyDerivation,
  digestMethodType = DefaultDigestMethodType,
  maxAge: int = 14 * 24 * 60 * 60, # 14 days, in seconds
  path = "",
  domain = "",
  sameSite = Lax,
  httpOnly = false
  ): HandlerAsync =

  if secretKey.len == 0:
    raise newException(BadSecretKeyError, "The length of secret key can't be zero")
  let signer = initTimedSigner(secretKey, salt, sep, keyDerivation, digestMethodType)
  result = proc(ctx: Context) {.async.} =
    # TODO make sure {':', ',', '}'} notin key or value
    let
      data = ctx.getCookie(sessionName)

    try:
      ctx.session.loads(signer.unsign(data, maxAge))
    except BadTimeSignatureError, SignatureExpiredError, ValueError:
      # BadTimeSignature, SignatureExpired or ValueError
      discard

    await switch(ctx)

    if ctx.session.len == 0: # empty or modified(del or clear)
      if ctx.session.modified: # modified
        ctx.deleteCookie(sessionName, domain = domain,
            path = path) # delete session data in cookie
      return

    if ctx.session.accessed:
      ctx.addHeader("vary", "Cookie")

    ctx.setCookie(sessionName, signer.sign(dumps(ctx.session)), maxAge = some(
        maxAge), path = path, domain = domain, sameSite = sameSite,
        httpOnly = httpOnly)
