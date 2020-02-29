import asyncdispatch, httpcore, strtabs
from htmlgen import input

from ../core/urandom import randomBytesSeq, randomString, DefaultEntropy
from ../core/encode import urlsafeBase64Encode, urlsafeBase64Decode
from ../core/middlewaresbase import switch
from ../core/context import Context, HandlerAsync, getCookie, setCookie


when not defined(production):
  import ../naive/request


const
  DefaultTokenName* = "CSRFToken"
  DefaultSecretSize* = 32
  DefaultTokenSize* = 64


proc getToken*(ctx: Context, tokenName = DefaultTokenName): string {.inline.} =
  ctx.getCookie(tokenName)

proc setToken*(ctx: Context, value: string, tokenName = DefaultTokenName) {.inline.} =
  ctx.setCookie(tokenName, value)

proc reject(ctx: Context) {.inline.} =
  ctx.response.status = Http403

proc makeToken(secret: openArray[byte]): string =
  let
    secret = randomBytesSeq(DefaultSecretSize)

  var
    mask = randomBytesSeq(DefaultSecretSize)
    token = newSeq[byte](DefaultTokenSize)

  for idx in DefaultSecretSize ..< DefaultTokenSize:
    token[idx] = mask[idx] + secret[idx]

  token[0 ..< DefaultSecretSize] = move mask

  result = token.urlsafeBase64Encode

proc recoverToken(token: string): seq[byte] =
  let
    token = token.urlsafeBase64Decode

  result = newSeq[byte](DefaultSecretSize)
  for idx in 0 ..< DefaultSecretSize:
    result[idx] = byte(token[idx]) - byte(token[DefaultSecretSize + idx])

proc generateToken*(ctx: Context, tokenName = DefaultTokenName): string =
  let tok = ctx.getToken(tokenName)
  if tok.len == 0:
    let secret = randomBytesSeq(DefaultSecretSize)
    result = makeToken(secret)
    ctx.setToken(result, tokenName)
  else:
    let secret = recoverToken(tok)
    result = makeToken(secret)

proc checkToken*(checked, secret: string): bool =
  let
    checked = checked.recoverToken
    secret = secret.recoverToken

  checked == secret

proc csrfToken*(ctx: Context, tokenName = DefaultTokenName): string {.inline.} =
  input(`type` = "hidden", name = tokenName, value = generateToken(ctx, tokenName))

# logging potential csrf attack
proc CsrfMiddleWare*(tokenName = DefaultTokenName): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    # "safe method"
    if ctx.request.reqMethod in {HttpGet, HttpHead, HttpOptions, HttpTrace}:
      await switch(ctx)
      return

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

    await switch(ctx)

    if ctx.getToken(tokenName).len != 0:
      return
    ctx.setToken(ctx.request.postParams[tokenName])
