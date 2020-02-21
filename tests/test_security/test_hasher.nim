import ../../src/prologue/security/hasher
from ../../src/prologue/core/types import SecretKey

import unittest


suite "Test Hasher":
  test "pbkdf2_sha256 can verify correct password":
    let res = pbkdf2_sha256encode(SecretKey("flywind"), "prologue")
    check pbkdf2_sha256verify(SecretKey("flywind"), res)

  test "pbkdf2_sha256 can verify wrong password":
    let res = pbkdf2_sha256encode(SecretKey("flywind"), "prologue")
    check not pbkdf2_sha256verify(SecretKey("flywin"), res)

  test "pbkdf2_sha1 can verify correct password":
    let res = pbkdf2_sha1encode(SecretKey("flywind"), "prologue")
    check pbkdf2_sha1verify(SecretKey("flywind"), res)

  test "pbkdf2_sha1 can verify wrong password":
    let res = pbkdf2_sha1encode(SecretKey("flywind"), "prologue")
    check not pbkdf2_sha1verify(SecretKey("flywin"), res)
