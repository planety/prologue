from strutils import strip
from nimcrypto import randomBytes

from ../core/types import SecretKey
from ../core/encode import urlsafeBase64Encode


const
  DefaultEntropy* = 32


proc randomBytesSeq*(size = DefaultEntropy): seq[byte] {.inline.} =
  result = newSeq[byte](size)
  discard randomBytes(result)

proc randomString*(size = DefaultEntropy): string {.inline.} =
  result = randomBytesSeq(size).urlsafeBase64Encode.strip(leading = false,
      chars = {'='})

proc randomSecretKey*(size = DefaultEntropy): SecretKey {.inline.} =
  result = SecretKey(randomString(size))


when isMainModule:
  for i in 1 .. 50:
    echo randomString(i).len
