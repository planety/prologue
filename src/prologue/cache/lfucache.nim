import std/[tables, options, times]


type
  ValuePair[B] = object
    valuePart: B
    hits: int
    expire: int # seconds

  LFUCache*[A, B] = object
    map: Table[A, ValuePair[B]]
    capacity: int
    defaultTimeout: int # seconds


func capacity*[A, B](cache: LFUCache[A, B]): int {.inline.} =
  cache.capacity

func len*[A, B](cache: LFUCache[A, B]): int {.inline.} =
  cache.map.len

func isEmpty*[A, B](cache: LFUCache[A, B]): bool {.inline.} =
  cache.len == 0

func isFull*[A, B](cache: LFUCache[A, B]): bool {.inline.} =
  cache.len == cache.capacity

func initLFUCache*[A, B](capacity: Natural = 128, defaultTimeout: Natural = 1): LFUCache[A, B] {.inline.} =
  LFUCache[A, B](map: initTable[A, ValuePair[B]](), capacity: capacity, defaultTimeout: defaultTimeout)

proc get*[A, B](cache: var LFUCache[A, B], key: A): Option[B] {.inline.} =
  if key in cache.map:
    inc cache.map[key].hits
    cache.map[key].expire = int(epochTime()) + cache.defaultTimeout
    return some(cache.map[key].valuePart)
  result = none(B)

proc getOrDefault*[A, B](cache: var LFUCache[A, B], key: A, default: B): B {.inline.} =
  let value = cache.get(key)

  if value.isSome:
    result = value.get
  else:
    result = default

proc put*[A, B](cache: var LFUCache[A, B], key: A, value: B, timeout: Natural = 1) =
  if key in cache.map:
    cache.map[key].hits += 1
    cache.map[key].valuePart = value
    cache.map[key].expire = int(cpuTime()) + timeout
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
    let now = int(cpuTime())
    for key, value in cache.map.pairs:
      if value.expire >= now:
        allDelkey.add(key)

    for key in allDelKey:
      cache.map.del(key)

  cache.map[key] = ValuePair[B](valuePart: value, hits: 0, expire: int(epochTime()) + timeout)

func hasKey*[A, B](cache: var LFUCache[A, B], key: A): bool {.inline.} =
  if cache.map.hasKey(key):
    result = true

func contains*[A, B](cache: var LFUCache[A, B], key: A): bool {.inline.} =
  cache.hasKey(key)


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
