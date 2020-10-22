import std/[strutils, strformat]

from ../core/context import Context, HandlerAsync
from ../core/response import setHeader, hasHeader
from ../core/encode import base64Decode
import ../core/request
import ../core/httpcore/httplogue


type
  AuthMethod* = enum
    Basic = "Basic"
    Digest = "Digest"
  VerifyHandler* = proc(ctx: Context, username, password: string): bool {.gcsafe.}


proc unauthenticate*(ctx: Context, authMethod: AuthMethod, realm: string,
    charset = "UTF-8") {.inline.} =
  ctx.response.code = Http401
  ctx.response.setHeader("WWW-Authenticate",
                         fmt"{authMethod} realm={realm}, charset={charset}")

proc basicAuth*(
  ctx: Context, realm: string, verify: VerifyHandler, 
  charset = "UTF-8"
): tuple[hasValue: bool, username, password: string] =
  result = (false, "", "")
  if not ctx.request.hasHeader("Authorization"):
    unauthenticate(ctx, Basic, realm, charset)
    return

  let
    text = ctx.request.headers["Authorization", 0]
    authorization = text.split(' ', maxsplit = 1)
    authMethod = authorization[0]
    authData = authorization[1]

  if authMethod.toLowerAscii != "basic":
    unauthenticate(ctx, Basic, realm, charset)
    ctx.response.body = "Unsupported Authorization Method"
    return

  var decoded: string
  try:
    decoded = base64Decode(authData)
  except ValueError:
    ctx.response.code = Http403
    ctx.response.body = "Base64 Decode Fails"
    return

  let
    user = decoded.split(":", maxsplit = 1)
    username = user[0]
    password = user[1]

  if ctx.verify(username, password):
    return (true, username, password)
  else:
    unauthenticate(ctx, Basic, realm, charset)
    ctx.response.body = "Forbidden"
    return
