import std/[options, strtabs, tables, asyncdispatch]

from ../../core/types import BadSecretKeyError, SecretKey, len, Session, newSession
from ../../core/context import Context, HandlerAsync, getCookie, setCookie,
                              deleteCookie
from ../../core/urandom import randomBytesSeq
from ../../core/response import addHeader
from ../../core/middlewaresbase import switch
from ../../core/nativesettings import Settings
from ../../core/encode import urlsafeBase64Encode

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

  var memorySessionTable = newTable[string, Session]()

  result = proc(ctx: Context) {.async.} =
    var
      data = ctx.getCookie(sessionName)

    if data.len != 0 and memorySessionTable.hasKey(data):
      ctx.session = memorySessionTable[data]
    else:
      ctx.session = newSession(data = newStringTable(modeCaseSensitive))

      data = urlsafeBase64Encode(randomBytesSeq(16))
      ctx.setCookie(sessionName, data, 
              maxAge = some(maxAge), path = path, domain = domain, 
              sameSite = sameSite, httpOnly = httpOnly, secure = secure)
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
