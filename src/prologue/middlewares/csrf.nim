import httpcore, strtabs,json
from htmlgen import input


import ../core/dispatch
from ../core/urandom import randomBytesSeq, randomString, DefaultEntropy
from ../core/encode import urlsafeBase64Encode, urlsafeBase64Decode
from ../core/middlewaresbase import switch
from ../core/context import Context, HandlerAsync,getPostParams
import ../core/request
import ../core/types
import uuids

const
  DefaultTokenName* = "CSRFToken"
  DefaultSecretSize* = 32
  DefaultTokenSize* = 64


proc getToken*(ctx: Context, tokenName = DefaultTokenName): string {.inline.} =
  ctx.session.getOrDefault(tokenName)

proc setToken*(ctx: Context, value: string, tokenName = DefaultTokenName) {.inline.} =
  ctx.session[tokenName] = value

proc reject*(ctx: Context) {.inline.} =
  ctx.response.code = Http403

proc generateToken*(ctx: Context, tokenName = DefaultTokenName): string {.inline.} =
  let 
      token = $genUUid()
  result = token.urlsafeBase64Encode()
  ctx.session[tokenName] = result
   
proc checkToken*(checked:string,token:string): bool {.inline.} =
  echo "checking token checked: ",checked," ",token
  result = checked == token
  echo result

# logging potential csrf attack
proc csrfMiddleWare*(tokenName = DefaultTokenName): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    # "safe method"
    if ctx.request.reqMethod in {HttpGet, HttpHead, HttpOptions, HttpTrace}:
      await switch(ctx)
      return

    # # don't submit forms multi-times
    # if ctx.request.cookies.hasKey("csrf_used"):
    #   ctx.deleteCookie("csrf_used")
    #   reject(ctx)
    #   return

    # forms don't send hidden values
    if not ctx.request.postParams.hasKey(tokenName):
      reject(ctx)
      return

    # forms don't use csrfToken
    if ctx.getToken(tokenName).len == 0:
      reject(ctx)
      return

    # not equal
    if not checkToken(ctx.request.postParams[tokenName], ctx.getToken(tokenName)):
      reject(ctx)
      return

    # # pass
    ctx.session.del(tokenName)

    await switch(ctx)
