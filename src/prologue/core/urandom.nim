# Copyright 2020 Zeshen Xing
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


from strutils import strip
from nimcrypto import randomBytes

from ../core/types import SecretKey
from ../core/encode import urlsafeBase64Encode


const
  DefaultEntropy* = 32


proc randomBytesSeq*(size = DefaultEntropy): seq[byte] {.inline.} =
  ## Generates System Random sequence of bytes.
  result = newSeq[byte](size)
  discard randomBytes(result)

proc randomString*(size = DefaultEntropy): string {.inline.} =
  ## Generates System Random strings.
  result = randomBytesSeq(size).urlsafeBase64Encode.strip(leading = false,
      chars = {'='})

proc randomSecretKey*(size = DefaultEntropy): SecretKey {.inline.} =
  ## Generates System Random SecretKey.
  result = SecretKey(randomString(size))


when isMainModule:
  for i in 1 .. 50:
    echo randomString(i).len
