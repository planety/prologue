import asyncdispatch
import httpcore, strutils, strformat


from ../core/context import Context, HandlerAsync, setHeader, hasHeader
from ../core/encode import base64Decode
from ../core/middlewaresbase import switch


type
  AuthMethod* = enum
    Basic = "Basic"
    Digest = "Digest"
  VerifyHandler* = proc(ctx: Context, userName, password: string): bool {.gcsafe.} 


proc unauthenticate*(ctx: Context, authMethod: AuthMethod, realm: string, charset = "UTF-8") {.inline.} =
  ctx.response.status = Http401
  ctx.setHeader("WWW-Authenticate", fmt"realm={realm}, charset={charset}")

proc basicAuth*(ctx: Context, authMethod: AuthMethod, realm: string, verify: VerifyHandler,
    charset = "UTF-8"): bool =
  if not ctx.hasHeader("Authorization"):
    unauthenticate(ctx, authMethod, realm, charset)
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

  if ctx.verify(userName, password):
    return true
  else:
    ctx.response.status = Http403
    ctx.response.body = "Forbidden"
    return false

proc basicAuthMiddleware*(realm: string, verifyHandler: VerifyHandler, authMethod = Basic,
  charset = "UTF-8"): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    if not basicAuth(ctx, authMethod, realm, verifyHandler, charset):
      return
    await switch(ctx)
