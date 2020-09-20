import options, strtabs


from cookiejar import SameSite

import asyncdispatch
from ../../core/types import BadSecretKeyError, SecretKey, len, Session, initSession
from ../../core/context import Context, HandlerAsync, getCookie, setCookie,
    deleteCookie
from ../../core/urandom import randomString
from ../../core/response import addHeader
from ../../signing/signing import DefaultSep, DefaultKeyDerivation,
    BadTimeSignatureError, SignatureExpiredError, DefaultDigestMethodType,
        initTimedSigner, unsign, sign
from ../../core/middlewaresbase import switch

import tables


export cookiejar


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

  var memorySessionTable = newTable[string, Session]()

  result = proc(ctx: Context) {.async.} =
    var
      data = ctx.getCookie(sessionName)

    if data.len != 0 and memorySessionTable.hasKey(data):
      ctx.session = memorySessionTable[data]
    else:
      ctx.session = initSession(data = newStringTable(modeCaseSensitive))

      data = randomString(16)
      ctx.setCookie(sessionName, data, 
              maxAge = some(maxAge), path = path, domain = domain, 
              sameSite = sameSite, httpOnly = httpOnly)
      memorySessionTable[data] = ctx.session

    await switch(ctx)

    if ctx.session.len == 0: # empty or modified(del or clear)
      if ctx.session.modified: # modified
        memorySessionTable.del(data)
        ctx.deleteCookie(sessionName, domain = domain,
                        path = path) # delete session data in cookie
      return

    if ctx.session.accessed:
      ctx.response.addHeader("vary", "Cookie")

    if ctx.session.modified:
      memorySessionTable[data] = ctx.session
