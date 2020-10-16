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

template since*(version, body: untyped) {.dirty.} =
  ## limitation: can't be used to annotate a template (eg typetraits.get), would
  ## error: cannot attach a custom pragma.
  when (NimMajor, NimMinor) >= version:
    body

template sinceAPI*(version, body: untyped) {.dirty.} =
  ## limitation: can't be used to annotate a template (eg typetraits.get), would
  ## error: cannot attach a custom pragma.
  when (NimMajor, NimMinor) >= version:
    body

template beforeAPI*(version, body: untyped) {.dirty.} =
  ## limitation: can't be used to annotate a template (eg typetraits.get), would
  ## error: cannot attach a custom pragma.
  when (NimMajor, NimMinor) <= version:
    body

func toByteSeq*(str: string): seq[byte] {.inline.} =
  ## Converts a string to the corresponding byte sequence.
  @(str.toOpenArrayByte(0, str.high))

func fromByteSeq*(sequence: openArray[byte]): string {.inline.} =
  ## Converts a byte sequence to the corresponding string.
  let length = sequence.len
  if length > 0:
    result = newString(length)
    copyMem(result.cstring, sequence[0].unsafeAddr, length)

template castNumber(result, number: typed): untyped =
  ## Casts ``number`` to array[byte] in system endianness order.
  cast[typeof(result)](number)

func serialize*(number: int64): array[8, byte] {.inline.} =
  ## Serializes int64 to byte array.
  result = castNumber(result, number)

func serialize*(number: int32): array[4, byte] {.inline.} =
  ## Serializes int32 to byte array.
  result = castNumber(result, number)

func serialize*(number: int16): array[2, byte] {.inline.} =
  ## Serializes int16 to byte array.
  # result[0] = byte(number shr 8'u16)
  # result[1] = byte(number)
  result = castNumber(result, number)

func escape*(src: string): string =
  result = newStringOfCap(src.len)
  for c in src:
    case c
    of '&': result.add("&amp;")
    of '<': result.add("&lt;")
    of '>': result.add("&gt;")
    of '"': result.add("&quot;")
    of '\'': result.add("&#39;")
    of '/': result.add("&#x2F;")
    else: result.add(c)
