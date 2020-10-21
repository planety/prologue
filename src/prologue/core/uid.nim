import std/monotimes

import ./urandom, ./utils
from ./encode import urlsafeBase64Encode


proc genUid*(): string =
  ## Generates a simple user id.
  # TODO ADD Mac/IP address
  let tseq = serialize(getMonoTime().ticks)
  let rseq = randomBytesSeq[8]()
  var res: array[16, byte]
  res[0 ..< 8] = tseq
  res[8 .. ^1] = rseq
  result = urlsafeBase64Encode(res)
