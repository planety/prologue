import tables
import lists
import macros

import common


type
  LRUCached*[A, B] = object
    map*: Table[A, MapValue[A, B]]
    cached*: CachedKeyPair[A, B]
    info*: CachedInfo

proc initLruCached*[A, B](maxSize: Natural = 128): LRUCached[A, B] {.inline.} =
  LRUCached[A, B](map: initTable[A, MapValue[A, B]](),
      cached: initDoublyLinkedList[KeyPair[A, B]](), info: (hits: 0,
          misses: 0, maxSize: maxSize))

proc moveToFront*[A, B](x: var LRUCached[A, B], node: MapValue[A, B]) {.inline.} =
  x.cached.remove(node)
  x.cached.prepend(node)

proc get*[A, B](x: var LRUCached[A, B], key: A): B {.inline.} =
  if key in x.map:
    x.info.hits += 1
    let node = x.map[key]
    moveToFront(x, node)
    return node.value.valuePart
  x.info.misses += 1

proc put*[A, B](x: var LRUCached[A, B], key: A, value: B) {.inline.} =
  if key in x.map:
    x.info.hits += 1
    var node = x.map[key]
    node.value.valuePart = value
    moveToFront(x, node)
    return
  x.info.misses += 1
  if x.map.len >= x.info.maxSize:
    let node = x.cached.tail
    x.cached.remove(node)
    x.map.del(node.value.keyPart)
  let node = newDoublyLinkedNode((keyPart: key, valuePart: value))
  x.map[key] = node
  moveToFront(x, node)

proc `[]`*[A, B](x: var LRUCached[A, B], key: A): B {.inline.} =
  x.get(key)

proc `[]=`*[A, B](x: var LRUCached[A, B], key: A, value: B) {.inline.} =
  x.put(key, value)

proc contains*[A, B](x: var LRUCached[A, B], key: A): bool =
  if key in x.map:
    return true
  else:
    return false


when isMainModule:
  import random, timeit

  randomize(128)

  timeOnce("cached"):
    var s = initLRUCached[int, int](128)
    for i in 1 .. 100:
      s.put(rand(1 .. 126), rand(1 .. 126))
    s.put(5, 6)
    echo s.get(12)
    echo s.get(14)
    echo s.get(5)
    echo s.info
    echo s.map.len
