import asyncdispatch, httpcore, strtabs
from htmlgen import input

from ../core/urandom import randomString, DefaultEntropy
from ../core/middlewaresbase import switch
from ../core/context import Context, HandlerAsync, getCookie, setCookie


when not defined(production):
  import ../naive/request

const
  DefaultTokenName = "CSRFToken"

proc csrfToken*(ctx: Context, size = DefaultEntropy,
    tokenName = DefaultTokenName): string {.inline.} =
  input(`type` = "hidden", name = tokenName, value = randomString(size))

proc setToken*(ctx: Context, value: string, tokenName = DefaultTokenName) {.inline.} =
  ctx.setCookie(tokenName, value)

# logging potential csrf attack
proc CsrfMiddleWare*(tokenName = DefaultTokenName): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    # "safe method"
    if ctx.request.reqMethod in {HttpGet, HttpHead, HttpOptions, HttpTrace}:
      await switch(ctx)
      return


    await switch(ctx)

    ctx.setToken(ctx.request.postParams[tokenName])

