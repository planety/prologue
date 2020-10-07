import ../../../src/prologue/cache/lfucache
import std/options



proc putNeverExpired[A, B](cache: var LFUCache[A, B], key: A, value: B) =
  cache.put(key, value, 100000)


block:
  var s = initLFUCache[int, int](64)
  doAssert s.isEmpty

  s.putNeverExpired(1, 1)
  s.putNeverExpired(2, 2)
  s.putNeverExpired(3, 3)

  doAssert s.hasKey(1)
  doAssert s.hasKey(2)
  doAssert s.hasKey(3)

  doAssert 1 in s
  doAssert 2 in s
  doAssert 3 in s

  doAssert s.capacity == 64
  doAssert s.len == 3
  doAssert not s.isEmpty
  doAssert not s.isFull

  doAssert s.get(1).get == 1
  doAssert s.get(2).get == 2
  doAssert s.get(3).get == 3

  doAssert s.getOrDefault(1, 0) == 1
  doAssert s.getOrDefault(2, 0) == 2
  doAssert s.getOrDefault(3, 0) == 3

  doAssert s.getOrDefault(4, 999) == 999
