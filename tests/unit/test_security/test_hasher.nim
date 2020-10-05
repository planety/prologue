from ../../../src/prologue/security/hasher import pbkdf2_sha256encode,
    pbkdf2_sha1encode, pbkdf2_sha256verify, pbkdf2_sha1verify
from ../../../src/prologue/core/types import SecretKey


# "Test Hasher"
block:
  # "pbkdf2_sha256 can verify correct password"
  block:
    let res = pbkdf2_sha256encode(SecretKey("flywind"), "prologue")
    doAssert pbkdf2_sha256verify(SecretKey("flywind"), res)

  # "pbkdf2_sha256 can verify wrong password"
  block:
    let res = pbkdf2_sha256encode(SecretKey("flywind"), "prologue")
    doAssert not pbkdf2_sha256verify(SecretKey("flywin"), res)

  # "pbkdf2_sha1 can verify correct password"
  block:
    let res = pbkdf2_sha1encode(SecretKey("flywind"), "prologue")
    doAssert pbkdf2_sha1verify(SecretKey("flywind"), res)

  # "pbkdf2_sha1 can verify wrong password"
  block:
    let res = pbkdf2_sha1encode(SecretKey("flywind"), "prologue")
    doAssert not pbkdf2_sha1verify(SecretKey("flywin"), res)
