from nimcrypto import randomBytes

from ../core/types import SecretKey
from ../core/encode import urlsafeBase64Encode


const
  DefaultEntropy* = 32


proc randomBytesSeq*(size = DefaultEntropy): seq[byte] {.inline.} =
  result = newSeq[byte](size)
  discard randomBytes(result)

proc randomString*(size = DefaultEntropy): string {.inline.} =
  result = randomBytesSeq(size).urlsafeBase64Encode

proc randomSecretKey*(size = DefaultEntropy): SecretKey {.inline.} =
  result = SecretKey(randomString(size))


when isMainModule:
  for i in 1 .. 20:
    discard randomString(i)
