import ../../src/prologue/security/hasher
from ../../src/prologue/core/types import SecretKey

import unittest


suite "Test Hasher":
  test "can verify correct password":
    let res = pbkdf2_256encode(SecretKey("flywind"), "prologue")
    check pbkdf2_256verify(SecretKey("flywind"), res)

  test "can verify wrong password":
    let res = pbkdf2_256encode(SecretKey("flywind"), "prologue")
    check not pbkdf2_256verify(SecretKey("flywin"), res)
