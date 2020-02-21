import base64, strformat, strutils

import nimcrypto/pbkdf2

from ../core/types import SecretKey


const
  outLen = 64


proc pbkdf2_256encode*(password: SecretKey, salt: string,
    iterations = 24400): string {.inline.} =
  assert salt.len != 0 and '$' notin salt
  let output = encode(pbkdf2(sha256, string(password), salt, iterations, outLen))
  result = fmt"pdkdf2_256${salt}${iterations}${output}"

proc pbkdf2_256verify*(password: SecretKey, encoded: string): bool =
  let
    collections = encoded.split('$', maxSplit = 3)

  if collections.len < 4:
    return false
  let
    algorithm = collections[0]
    salt = collections[1]
    iterations = collections[2]
  if algorithm != "pdkdf2_256":
    return false

  return encoded == pbkdf2_256encode(password, salt, parseInt(iterations))


when isMainModule:
  let res = pbkdf2_256encode(SecretKey("flywind"), "prologue")
  assert pbkdf2_256verify(SecretKey("flywind"), res)
