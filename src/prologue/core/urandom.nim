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
from std/sysrand import urandom

from ./types import SecretKey
from ./utils import fromByteSeq


const
  DefaultEntropy* = 32    ## The default length of random string.


proc randomBytesSeq*(size = DefaultEntropy): seq[byte] {.inline.} =
  ## Generates a new system random sequence of bytes.
  result = newSeq[byte](size)
  discard urandom(result)

proc randomBytesSeq*[size: static[int]](): array[size, byte] {.inline.} =
  ## Generates a new system random sequence of bytes.
  discard urandom(result)

proc randomString*(size = DefaultEntropy): string {.inline.} =
  ## Generates a new system random strings.
  result = size.randomBytesSeq.fromByteSeq

proc randomSecretKey*(size = DefaultEntropy): SecretKey {.inline.} =
  ## Generates a new system random secretKey.
  result = SecretKey(randomString(size))


when isMainModule:
  for i in 1 .. 50:
    echo randomString(i).len
