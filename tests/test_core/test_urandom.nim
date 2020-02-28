from ../../src/prologue/core/types import SecretKey, len
from ../../src/prologue/core/urandom import randomString, randomSecretKey


import unittest


suite "Test Urandom":
  test "randomString can work":
    check randomString(8).len != 0

  test "randomSecretKey can work":
    check randomSecretKey(8).len != 0
