import asyncdispatch
import httpcore, strutils, strformat


from ../core/context import Context, HandlerAsync, setHeader, hasHeader
from ../core/encode import base64Decode
from ../core/middlewaresbase import switch


type
  VerifyHandler* = proc(ctx: Context, userName, password: string): bool


proc unauthenticate*(ctx: Context, realm: string, charset = "UTF-8") {.inline.} =
  ctx.response.status = Http401
  ctx.setHeader("WWW-Authenticate", fmt"realm={realm}, charset={charset}")

proc basicAuth*(ctx: Context, realm: string, verify: VerifyHandler,
    charset = "UTF-8"): bool =
  if not ctx.hasHeader("Authorization"):
    unauthenticate(ctx, realm, charset)
    return false

  let
    text = ctx.response.httpHeaders["Authorization", 0]
    authorization = text.split(' ', maxsplit = 1)
    authMethod = authorization[0]
    authData = authorization[1]

  if authMethod.toLowerAscii != "basic":
    ctx.response.status = Http403
    ctx.response.body = "Unsupported Authorization Method"
    return false

  # TODO auth username or password
  var decoded: string
  try:
    decoded = base64Decode(authData)
  except ValueError:
    ctx.response.status = Http403
    ctx.response.body = "Base64 Decode Fails"
    return false

  let
    user = decoded.split(":", maxsplit = 1)
    userName = user[0]
    password = user[1]
  return ctx.verify(userName, password)

proc basicAuthMiddleware*(realm: string, verifyHandler: VerifyHandler,
  charset = "UTF-8"): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    await switch(ctx)
