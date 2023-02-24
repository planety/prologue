import std/[options, strtabs, asyncdispatch]

from ../../core/types import BadSecretKeyError, SecretKey, len, Session, newSession, pairs
from ../../core/context import Context, HandlerAsync, getCookie, setCookie, deleteCookie
from ../../core/response import addHeader
from ../../core/middlewaresbase import switch
from ../../core/uid import genUid
from ../../core/nativesettings import Settings

from pkg/cookiejar import SameSite


when (compiles do: import redis):
  import pkg/redis
else:
  {.error: "Please use `logue extension redis` to install!".}

export cookiejar


func divide(info: RedisList): StringTableRef =
  result = newStringTable(modeCaseSensitive)
  for idx in countup(0, info.high, 2):
    result[info[idx]] = info[idx + 1]

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

  var redisClient = waitFor openAsync()

  result = proc(ctx: Context) {.async.} =
    var
      data = ctx.getCookie(sessionName)

    if data.len != 0:
      {.gcsafe.}:
        let info = await redisClient.hGetAll(data)

      if info.len != 0:
        ctx.session = newSession(data = divide(info))
      else:
        ctx.session = newSession(data = newStringTable(modeCaseSensitive))
    else:
      ctx.session = newSession(data = newStringTable(modeCaseSensitive))

      data = genUid()
      ctx.setCookie(sessionName, data, 
              maxAge = some(maxAge), path = path, domain = domain, 
              sameSite = sameSite, httpOnly = httpOnly, secure = secure)

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
