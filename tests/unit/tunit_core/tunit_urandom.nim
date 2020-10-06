from ../../../src/prologue/core/types import SecretKey, len
from ../../../src/prologue/core/urandom import randomString, randomSecretKey


# "Test Urandom"
block:
  # "randomString can work"
  block:
    doAssert randomString(8).len == 8

  # "randomSecretKey can work"
  block:
    doAssert randomSecretKey(8).len == 8
