from ../../src/prologue/core/types import SecretKey
from ../../src/prologue/signing/signing import initSigner, initTimedSigner,
    BaseDigestMethodType, BadSignatureError, sign, unsign, validate

import unittest, json


suite "Test signing":
  test "can sign with Signer":
    let
      key = SecretKey("secret-key")
      s = initSigner(key, salt = "itsdangerous.Signer",
          digestMethod = Sha512Type)
      sig = s.sign("my string")

    check:
      sig == "my string.Xu9Up4-UV7C46bh-AlQk86olom2irJLJJ" &
                "2wMMe5j5iuv4WKBgByR3wT3sWE3Pt6fqdqEANrO7sTwUvupadyPow"
      s.unsign(sig) == "my string"
      validate(s, sig)

  test "can sign with TimedSigner":
    let
      key = SecretKey("secret-key")
      s = initTimedSigner(key, salt = "activate",
          digestMethod = Sha1Type)
      sig = s.sign("my string")
    check s.unsign(sig, 0) == "my string"

  test "can sign with json string":
    let
      key = SecretKey("secret-key")
      s = initSigner(key, salt = "activate",
          digestMethod = Blake2_256Type)
    discard s.sign( $ %*[1, 2, 3])
    expect(BadSignatureError):
      discard s.unsign("[1, 2, 3].sdhfghjkjhdfghjigf")
