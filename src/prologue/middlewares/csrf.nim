# Copyright 2020 Zeshen Xing
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


import std/[strtabs, asyncdispatch]
from std/htmlgen import input

from ../core/urandom import randomBytesSeq, randomString, DefaultEntropy
from ../core/encode import urlsafeBase64Encode, urlsafeBase64Decode
from ../core/middlewaresbase import switch
from ../core/context import Context, HandlerAsync, getCookie, setCookie, deleteCookie
import ../core/request
import ../core/httpcore/httplogue


import pkg/cookiejar


const
  DefaultTokenName* = "CSRFToken"
  DefaultSecretSize* = 32
  DefaultTokenSize* = 64


proc getToken*(ctx: Context, tokenName = DefaultTokenName): string {.inline.} =
  ctx.getCookie(tokenName)

proc setToken*(ctx: Context, value: string, tokenName = DefaultTokenName) {.inline.} =
  ctx.setCookie(tokenName, value)

proc reject(ctx: Context) {.inline.} =
  ctx.response.code = Http403

proc makeToken(secret: openArray[byte]): string {.inline.} =
  var
    mask = randomBytesSeq(DefaultSecretSize)
    token = newSeq[byte](DefaultTokenSize)

  for idx in 0 ..< DefaultSecretSize:
    token[idx] = mask[idx] + secret[idx]

  token[DefaultSecretSize ..< DefaultTokenSize] = move mask

  result = token.urlsafeBase64Encode

proc recoverToken(token: string): seq[byte] {.inline.} =
  let
    token = token.urlsafeBase64Decode

  result = newSeq[byte](DefaultSecretSize)

  if token.len != DefaultTokenSize:
    return

  for idx in 0 ..< DefaultSecretSize:
    result[idx] = byte(token[idx]) - byte(token[DefaultSecretSize + idx])

proc generateToken*(ctx: Context, tokenName = DefaultTokenName): string {.inline.} =
  let tok = ctx.getToken(tokenName)
  if tok.len == 0:
    let secret = randomBytesSeq(DefaultSecretSize)
    result = makeToken(secret)
    ctx.setToken(result, tokenName)
  else:
    let secret = recoverToken(tok)
    result = makeToken(secret)

proc checkToken*(checked, secret: string): bool {.inline.} =
  let
    checked = checked.recoverToken
    secret = secret.recoverToken

  result = checked == secret

proc csrfToken*(ctx: Context, tokenName = DefaultTokenName): string {.inline.} =
  input(`type` = "hidden", name = tokenName, value = generateToken(ctx, tokenName))

# TODO logging potential csrf attack
proc csrfMiddleWare*(tokenName = DefaultTokenName): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    # "safe method"
    if ctx.request.reqMethod in {HttpGet, HttpHead, HttpOptions, HttpTrace}:
      await switch(ctx)
      return

    # don't submit forms multi-times
    if ctx.request.cookies.hasKey("csrf_used"):
      ctx.deleteCookie("csrf_used")
      reject(ctx)
      return

    # forms don't send hidden values
    if not ctx.request.postParams.hasKey(tokenName):
      reject(ctx)
      return

    # forms don't use csrfToken
    let token = ctx.getToken(tokenName)
    if token.len == 0:
      reject(ctx)
      return

    # not equal
    if not checkToken(ctx.request.postParams[tokenName], token):
      reject(ctx)
      return

    # pass
    ctx.setCookie("csrf_used", "")

    await switch(ctx)
