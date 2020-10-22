from ../../../src/prologue/core/types import SecretKey
from ../../../src/prologue/signing import initSigner, initTimedSigner,
    BaseDigestMethodType, BadSignatureError, sign, unsign, validate

import std/json


# "Test signing"
block:
  # "can sign with Signer"
  block:
    let
      key = SecretKey("secret-key")
      s = initSigner(key, salt = "itsdangerous.Signer",
          digestMethod = Sha512Type)
      sig = s.sign("my string")


    doAssert sig == "my string.Xu9Up4-UV7C46bh-AlQk86olom2irJLJJ" &
                    "2wMMe5j5iuv4WKBgByR3wT3sWE3Pt6fqdqEANrO7sTwUvupadyPow"
    doAssert s.unsign(sig) == "my string"
    doAssert validate(s, sig)

  # "can sign with TimedSigner"
  block:
    let
      key = SecretKey("secret-key")
      s = initTimedSigner(key, salt = "activate",
          digestMethod = Sha1Type)
      sig = s.sign("my string")
    doAssert s.unsign(sig, 0) == "my string"

  # "can sign with json string"
  block:
    let
      key = SecretKey("secret-key")
      s = initSigner(key, salt = "activate",
          digestMethod = Blake2_256Type)
    discard s.sign( $ %*[1, 2, 3])
    doAssertRaises(BadSignatureError):
      discard s.unsign("[1, 2, 3].sdhfghjkjhdfghjigf")
