import asyncdispatch, httpcore, strtabs
from htmlgen import input

from ../core/urandom import randomBytesSeq, randomString, DefaultEntropy
from ../core/encode import urlsafeBase64Encode, urlsafeBase64Decode
from ../core/middlewaresbase import switch
from ../core/context import Context, HandlerAsync, getCookie, setCookie


when not defined(production):
  import ../naive/request


const
  DefaultTokenName = "CSRFToken"


proc generateToken*(size = DefaultEntropy): string =
  let  
    secret = randomBytesSeq(size)
    tokenSize = size * 2
  
  var
    mask = randomBytesSeq(size)
    token = newSeq[byte](tokenSize)

  for idx in size ..< tokenSize:
    token[idx] = mask[idx] + secret[idx]

  token[0 ..< size] = move mask

  result = token.urlsafeBase64Encode

proc recoverToken(token: string): seq[byte] =
  let
    token = token.urlsafeBase64Decode
    secretSize = token.len div 2
  
  result = newSeq[byte](secretSize)
  for idx in 0 ..< secretSize:
    result[idx] = byte(token[idx]) - byte(token[secretSize + idx])

proc checkToken*(checked, secret: string): bool =
  let
    checked = checked.recoverToken
    secret = secret.recoverToken

  checked == secret
  
proc csrfToken*(ctx: Context, size = DefaultEntropy,
    tokenName = DefaultTokenName): string {.inline.} =
  input(`type` = "hidden", name = tokenName, value = randomString(size))

proc getToken*(ctx: Context, tokenName = DefaultTokenName): string {.inline.} =
  ctx.getCookie(tokenName)

proc setToken*(ctx: Context, value: string, tokenName = DefaultTokenName) {.inline.} =
  ctx.setCookie(tokenName, value)

proc reject(ctx: Context) {.inline.} =
  ctx.response.status = Http403

# logging potential csrf attack
proc CsrfMiddleWare*(tokenName = DefaultTokenName): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    # "safe method"
    if ctx.request.reqMethod in {HttpGet, HttpHead, HttpOptions, HttpTrace}:
      await switch(ctx)
      return

    if not checkToken(ctx.request.postParams[tokenName], ctx.getToken(tokenName)):
      reject(ctx)
      return

    await switch(ctx)

    if ctx.getToken(tokenName).len != 0:
      return
    ctx.setToken(ctx.request.postParams[tokenName])
