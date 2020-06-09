import httpcore, strtabs
from htmlgen import input
import uuids

import karax / [karaxdsl, vdom]
import cookiejar

import ../core/dispatch
from ../core/urandom import randomBytesSeq, randomString, DefaultEntropy
from ../core/encode import urlsafeBase64Encode, urlsafeBase64Decode
from ../core/middlewaresbase import switch
from ../core/context import Context, HandlerAsync, getCookie, setCookie, deleteCookie
import ../core/request
import ../core/types


const
  DefaultTokenName* = "CSRFToken"
  DefaultSecretSize* = 32
  DefaultTokenSize* = 64

proc getToken*(ctx: Context, tokenName = DefaultTokenName): string {.inline.} =
  result = ctx.session.getOrDefault(tokenName)
 
proc setToken*(ctx: Context, value: string, tokenName = DefaultTokenName) {.inline.} =
  ctx.session[tokenName] = value

proc reject(ctx: Context) {.inline.} =
  ctx.response.code = Http403


proc generateToken*(ctx: Context, tokenName = DefaultTokenName): string {.inline.} =
  let tok = ctx.getToken(tokenName)
  if tok.len == 0:
    result = urlsafeBase64Encode($genUUID())
    ctx.setToken(result, tokenName)
  else:
    result = tok
    
proc csrfToken*(ctx: Context, tokenName = DefaultTokenName): VNode {.inline.} =
  result = flatHtml(input(`type` = "hidden", name = tokenName, value = generateToken(ctx, tokenName)))

# logging potential csrf attack
proc csrfMiddleWare*(tokenName = DefaultTokenName): HandlerAsync =
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
    if not (ctx.request.postParams[tokenName] == ctx.getToken(tokenName)):
      reject(ctx)
      return

    # pass
    ctx.session.del(tokenName)

    await switch(ctx)
