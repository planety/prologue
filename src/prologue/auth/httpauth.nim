import httpcore, strutils, strformat

from ../core/context import Context, setHeader, hasHeader
from ../core/encode import base64Decode


proc unauthenticate*(ctx: Context, realm: string, charset = "") =
  ctx.response.status = Http401
  ctx.setHeader("WWW-Authenticate", fmt"realm={realm}, charset={charset}")

proc basicAuth*(ctx: Context): bool =
  if not ctx.hasHeader("Authorization"):
    ctx.response.status = Http403
    ctx.response.body = "Authorization Required"
    return false

  let 
    text = ctx.response.httpHeaders["Authorization", 0]
    authorization = text.split(' ', maxsplit = 1)
    authMethod =  authorization[0]
    authData = authorization[1]

  if authMethod.toLowerAscii != "basic":
    ctx.response.status = Http403
    ctx.response.body = "Unsupported Authorization Method"
    return false

  # TODO verify
  var pairs: string
  try:
    pairs = base64Decode(authData)
  except ValueError:
    ctx.response.status = Http403
    ctx.response.body = "Base64 Decode Fails"
    return

  return true
   
  