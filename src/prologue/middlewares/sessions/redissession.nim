import options, strtabs


from cookiejar import SameSite

import asyncdispatch
from ../../core/types import BadSecretKeyError, SecretKey, len, Session, initSession, pairs
from ../../core/context import Context, HandlerAsync, getCookie, setCookie,
    deleteCookie
from ../../core/urandom import randomString
from ../../core/response import addHeader
from ../../signing/signing import DefaultSep, DefaultKeyDerivation,
    BadTimeSignatureError, SignatureExpiredError, DefaultDigestMethodType,
        initTimedSigner, unsign, sign
from ../../core/middlewaresbase import switch

when not (compiles do: import redis):
  {.error: "Please use `logue extension redis` to install!".}
else:
  import redis

export cookiejar


proc divide(info: RedisList): StringTableRef =
  result = newStringTable(modeCaseSensitive)
  for idx in countup(0, info.high, 2):
    result[info[idx]] = info[idx + 1]

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

  ## TODO
  # {.gcsafe.}:
  var redisClient = waitFor openAsync()

  result = proc(ctx: Context) {.async.} =
    var
      data = ctx.getCookie(sessionName)

    if data.len != 0:
      {.gcsafe.}:
        let info = await redisClient.hGetAll(data)

      if info.len != 0:
        ctx.session = initSession(data = divide(info))
      else:
        ctx.session = initSession(data = newStringTable(modeCaseSensitive))
    else:
      ctx.session = initSession(data = newStringTable(modeCaseSensitive))

      ## TODO sign or encrypt it
      data = randomString(16)
      ctx.setCookie(sessionName, data, 
              maxAge = some(maxAge), path = path, domain = domain, 
              sameSite = sameSite, httpOnly = httpOnly)

    await switch(ctx)

    if ctx.session.len == 0: # empty or modified(del or clear)
      if ctx.session.modified: # modified
        {.gcsafe.}:
          discard await redisClient.del(@[data])
        ctx.deleteCookie(sessionName, domain = domain,
                        path = path) # delete session data in cookie
      return

    if ctx.session.accessed:
      ctx.response.addHeader("vary", "Cookie")

    if ctx.session.modified:
      let length = ctx.session.len
      var temp = newSeqOfCap[(string, string)](length)
      for (key, val) in ctx.session.pairs:
        temp.add (key, val)
      {.gcsafe.}:
        await redisClient.hMset(data, temp)
