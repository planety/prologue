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

{.deprecated.}

import std/[strformat, strutils]

import pkg/nimcrypto/pbkdf2

from ../core/types import SecretKey
from ../core/encode import base64Encode


const
  outLen = 64 ## Default length.


proc pbkdf2_sha256encode*(password: SecretKey, salt: string,
                          iterations = 24400): string {.inline.} =
  doAssert salt.len != 0 and '$' notin salt
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
  doAssert salt.len != 0 and '$' notin salt
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
  doAssert pbkdf2_sha256verify(SecretKey("flywind"), r1)

  let r2 = pbkdf2_sha1encode(SecretKey("flywind"), "prologue")
  doAssert pbkdf2_sha1verify(SecretKey("flywind"), r2)
