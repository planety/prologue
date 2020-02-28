import strformat, strutils

import nimcrypto/pbkdf2

from ../core/types import SecretKey
from ../core/encode import base64Encode


const
  outLen = 64


proc pbkdf2_sha256encode*(password: SecretKey, salt: string,
    iterations = 24400): string {.inline.} =
  assert salt.len != 0 and '$' notin salt
  let output = base64Encode(pbkdf2(sha256, string(password), salt, iterations, outLen))
  result = fmt"pdkdf2_sha256${salt}${iterations}${output}"

proc pbkdf2_sha256verify*(password: SecretKey, encoded: string): bool =
  let
    collections = encoded.split('$', maxSplit = 3)

  if collections.len < 4:
    return false
  let
    algorithm = collections[0]
    salt = collections[1]
    iterations = collections[2]
  if algorithm != "pdkdf2_sha256":
    return false

  return encoded == pbkdf2_sha256encode(password, salt, parseInt(iterations))

proc pbkdf2_sha1encode*(password: SecretKey, salt: string,
  iterations = 24400): string {.inline.} =
  assert salt.len != 0 and '$' notin salt
  let output = base64Encode(pbkdf2(sha1, string(password), salt, iterations, outLen))
  result = fmt"pdkdf2_sha1${salt}${iterations}${output}"

proc pbkdf2_sha1verify*(password: SecretKey, encoded: string): bool =
  let
    collections = encoded.split('$', maxSplit = 3)

  if collections.len < 4:
    return false
  let
    algorithm = collections[0]
    salt = collections[1]
    iterations = collections[2]
  if algorithm != "pdkdf2_sha1":
    return false
  return encoded == pbkdf2_sha1encode(password, salt, parseInt(iterations))


when isMainModule:
  let r1 = pbkdf2_sha256encode(SecretKey("flywind"), "prologue")
  assert pbkdf2_sha256verify(SecretKey("flywind"), r1)

  let r2 = pbkdf2_sha1encode(SecretKey("flywind"), "prologue")
  assert pbkdf2_sha1verify(SecretKey("flywind"), r2)
