import std/[options, strtabs, asyncdispatch, json]


from ../../core/types import BadSecretKeyError, SecretKey, loads, dumps, len, newSession
from ../../core/context import Context, HandlerAsync, getCookie, setCookie,
    deleteCookie
from ../../core/response import addHeader
from ../../signing/signing import DefaultSep, DefaultKeyDerivation,
    BadTimeSignatureError, SignatureExpiredError, DefaultDigestMethodType,
        initTimedSigner, unsign, sign
from ../../core/middlewaresbase import switch
from ../../core/urandom import randomString
from ../../core/nativesettings import Settings, `[]`

from pkg/cookiejar import SameSite

export cookiejar


proc sessionMiddleware*(
  settings: Settings,
  sessionName = "session",
  maxAge: int = 14 * 24 * 60 * 60, # 14 days, in seconds
  path = "",
  domain = "",
  sameSite = Lax,
  httpOnly = false,
  secure = false
): HandlerAsync =

  var secretKey = settings["prologue"].getOrDefault("secretKey").getStr
  if secretKey.len == 0:
    secretKey = randomString(16)

  let
    salt = "prologue.signedcookiesession"
    sep = DefaultSep
    keyDerivation = DefaultKeyDerivation
    digestMethodType = DefaultDigestMethodType
    signer = initTimedSigner(SecretKey(secretKey), salt, sep, keyDerivation, digestMethodType)

  result = proc(ctx: Context) {.async.} =
    ctx.session = newSession(data = newStringTable(modeCaseSensitive))
    let
      data = ctx.getCookie(sessionName)

    if data.len != 0:
      try:
        ctx.session.loads(signer.unsign(data, maxAge))
      except BadTimeSignatureError, SignatureExpiredError, ValueError, IndexDefect:
        ctx.deleteCookie(sessionName, domain = domain,
                path = path) # delete session data in cookie
      except Exception as e:
        ctx.deleteCookie(sessionName, domain = domain,
                path = path) # delete session data in cookie
        raise e

    await switch(ctx)

    if ctx.session.len == 0: # empty or modified(del or clear)
      if ctx.session.modified: # modified
        ctx.deleteCookie(sessionName, domain = domain,
                        path = path) # delete session data in cookie
      return

    if ctx.session.accessed:
      ctx.response.addHeader("vary", "Cookie")

    # TODO add refresh every request[in permanent session]
    if ctx.session.modified:
      ctx.setCookie(sessionName, signer.sign(dumps(ctx.session)), 
                    maxAge = some(maxAge), path = path, domain = domain, 
                    sameSite = sameSite, httpOnly = httpOnly, secure = secure)
