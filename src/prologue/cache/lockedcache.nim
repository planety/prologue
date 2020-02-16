import tables
import lists
import rlocks

import common


type
  LockedLRUCached*[A, B] = ref object
    map: Table[A, MapValue[A, B]]
    cached: CachedKeyPair[A, B]
    info: CachedInfo
    rlock: RLock


proc newLockedLRUCached*[A, B](maxSize: Natural = 128): LockedLRUCached[A, B] =
  var rlock: RLock
  initRLock(rlock)
  LockedLRUCached[A, B](map: initTable[A, MapValue[A, B]](),
      cached: initDoublyLinkedList[KeyPair[A, B]](), info: (hits: 0,
          misses: 0, maxSize: maxSize), rlock: rlock)

proc moveToFront*[A, B](x: var LockedLRUCached[A, B], node: MapValue[A, B]) =
  x.cached.remove(node)
  x.cached.prepend(node)

proc get*[A, B](x: var LockedLRUCached[A, B], key: A): B =
  if key in x.map:
    withRLock x.rlock:
      x.info.hits += 1
      let node = x.map[key]
      moveToFront(x, node)
      return node.value.valuePart
  withRLock x.rlock:
    x.info.misses += 1

proc put*[A, B](x: var LockedLRUCached[A, B], key: A, value: B) =
  if key in x.map:
    withRLock x.rlock:
      x.info.hits += 1
      var node = x.map[key]
      node.value.valuePart = value
      moveToFront(x, node)
      return
  withRLock x.rlock:
    x.info.misses += 1

  if x.map.len >= x.info.maxSize:
    let node = x.cached.tail
    withRLock x.rlock:
      x.cached.remove(node)
      x.map.del(node.value.keyPart)

  withRLock x.rlock:
    let node = newDoublyLinkedNode((keyPart: key, valuePart: value))
    x.map[key] = node
    moveToFront(x, node)


when isMainModule:
  import random, timeit

  randomize(128)
  
  timeOnce("cached"):
    var s = newLockedLRUCached[int, int](128)
    for i in 1 .. 100:
      s.put(rand(1 .. 126), rand(1 .. 126))
    s.put(5, 6)
    echo s.get(12)
    echo s.get(14)
    echo s.get(5)
    echo s.info
    echo s.map.len
