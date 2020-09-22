import tables, options, times


type
  ValuePair[B] = object
    valuePart: B
    hits: int
    expire: int # seconds

  LFUCache*[A, B] = object
    map: Table[A, ValuePair[B]]
    capacity: int
    defaultTimeout: int # seconds

proc capacity*[A, B](cache: LFUCache[A, B]): int =
  cache.capacity

proc len*[A, B](cache: LFUCache[A, B]): int =
  cache.map.len

proc isBool*[A, B](cache: LFUCache[A, B]): bool =
  cache.len == 0

proc isFull*[A, B](cache: LFUCache[A, B]): bool =
  cache.len == cache.capacity

proc initLFUCache*[A, B](capacity: Natural = 128, defaultTimeout: Natural = 1): LFUCache[A, B] =
  LFUCache[A, B](map: initTable[A, ValuePair[B]](), capacity: capacity, defaultTimeout: defaultTimeout)

proc get*[A, B](cache: var LFUCache[A, B], key: A): Option[B] =
  if key in cache.map:
    inc cache.map[key].hits
    cache.map[key].expire = int(epochTime()) + cache.defaultTimeout
    return some(cache.map[key].valuePart)
  result = none(B)

proc put*[A, B](cache: var LFUCache[A, B], key: A, value: B, expire: Natural) =
  if key in cache.map:
    cache.map[key].hits += 1
    cache.map[key].valuePart = value
    cache.map[key].expire = int(cpuTime()) + expire
    return

  if cache.map.len >= cache.capacity:
    var minValue = high(int)
    var minkey: B
    for key in cache.map.keys:
      if cache.map[key].hits < minValue:
        minValue = cache.map[key].hits
        minkey = key
    cache.map.del(minKey)

    var allDelKey: seq[A]
    for key, value in cache.map.pairs:
      if value.expire >= int(cpuTime()):
        allDelkey.add(key)

    for key in allDelKey:
      cache.map.del(key)
  cache.map[key] = ValuePair[B](valuePart: value, hits: 0, expire: 12)


when isMainModule:
  import random, timeit, times, os

  randomize(128)

  var s = initLFUCache[int, int](128)
  for i in 1 .. 1000:
    s.put(rand(1 .. 200), rand(1 .. 126), rand(2 .. 4))
  s.put(5, 6, 3)
  echo s.get(12)
  echo s.get(14).isNone
  echo s.get(5)
  echo s.len
  sleep(5)
  echo s.map
