import redis, asyncdispatch

proc main() {.async.} =
  ## Open a connection to Redis running on localhost on the default port (6379)
  

  ## Set the key `nim_redis:test` to the value `Hello, World`
  await redisClient.setk("nim_redis:test", "Hello, World")

  ## Get the value of the key `nim_redis:test`
  let value = await redisClient.get("nim_redis:test")

  assert(value == "Hello, World")


import options, strtabs


from cookiejar import SameSite

import asyncdispatch
from ../../core/types import BadSecretKeyError, SecretKey, loads, dumps, len, initSession
from ../../core/context import Context, HandlerAsync, getCookie, setCookie,
    deleteCookie
from ../../core/response import addHeader
from ../../signing/signing import DefaultSep, DefaultKeyDerivation,
    BadTimeSignatureError, SignatureExpiredError, DefaultDigestMethodType,
        initTimedSigner, unsign, sign
from ../../core/middlewaresbase import switch


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

  let redisClient = await openAsync()
  
  let signer = initTimedSigner(secretKey, salt, sep, keyDerivation, digestMethodType)
  
  result = proc(ctx: Context) {.async.} =
    # TODO make sure {':', ',', '}'} notin key or value
    ctx.session = initSession(data = newStringTable(modeCaseSensitive))
    let
      data = ctx.getCookie(sessionName)

    if data.len != 0:
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
      ctx.response.addHeader("vary", "Cookie")

    # TODO add refresh every request[in permanent session]
    if ctx.session.modified:
      ctx.setCookie(sessionName, signer.sign(dumps(ctx.session)), 
                    maxAge = some(maxAge), path = path, domain = domain, 
                    sameSite = sameSite, httpOnly = httpOnly)
