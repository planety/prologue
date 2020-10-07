import std/[tables, lists, options, times]


type
  KeyPair[A, B] = tuple
    keyPart: A
    valuePart: B
    expire: int # seconds

  ListPair*[A, B] = DoublyLinkedList[KeyPair[A, B]]
  MapValue*[A, B] = DoublyLinkedNode[KeyPair[A, B]]

  LRUCache*[A, B] = object
    map: Table[A, MapValue[A, B]]
    list: ListPair[A, B]
    capacity: int
    defaultTimeout: int # seconds


func capacity*[A, B](cache: LRUCache[A, B]): int {.inline.} =
  cache.capacity

func len*[A, B](cache: LRUCache[A, B]): int {.inline.} =
  cache.map.len

func isEmpty*[A, B](cache: LRUCache[A, B]): bool {.inline.} =
  cache.len == 0

func isFull*[A, B](cache: LRUCache[A, B]): bool {.inline.} =
  cache.len == cache.capacity

func initLRUCache*[A, B](capacity: Natural = 128, defaultTimeout: Natural = 1): LRUCache[A, B] {.inline.} =
  LRUCache[A, B](map: initTable[A, MapValue[A, B]](),
                 list: initDoublyLinkedList[KeyPair[A, B]](), 
                 capacity: capacity,
                 defaultTimeout: defaultTimeout
                 )

proc moveToFront*[A, B](cache: var LRUCache[A, B], node: MapValue[A, B]) {.inline.} =
  cache.list.remove(node)
  cache.list.prepend(node)

proc get*[A, B](cache: var LRUCache[A, B], key: A): Option[B] {.inline.} =
  if key in cache.map:
    var node = cache.map[key]
    node.value.expire = int(epochTime()) + cache.defaultTimeout
    moveToFront(cache, node)
    return some(node.value.valuePart)
  result = none(B)

proc getOrDefault*[A, B](cache: var LRUCache[A, B], key: A, default: B): B {.inline.} =
  let value = cache.get(key)

  if value.isSome:
    result = value.get
  else:
    result = default

proc put*[A, B](cache: var LRUCache[A, B], key: A, value: B, timeout: Natural = 1) =
  if key in cache.map:
    var node = cache.map[key]
    node.value.valuePart = value
    node.value.expire = int(epochTime()) + timeout
    moveToFront(cache, node)
    return

  if cache.map.len >= cache.capacity:
    let node = cache.list.tail
    cache.list.remove(node)
    cache.map.del(node.value.keyPart)

    let now = int(epochTime())
    for cnode in nodes(cache.list):
      if now > cnode.value.expire:
        cache.list.remove(cnode)
        cache.map.del(cnode.value.keyPart)

  let node = newDoublyLinkedNode((keyPart: key, valuePart: value, expire: int(epochTime()) + timeout))
  cache.map[key] = node
  moveToFront(cache, node)

proc `[]`*[A, B](cache: var LRUCache[A, B], key: A): B {.inline.} =
  cache.get(key)

func hasKey*[A, B](cache: var LRUCache[A, B], key: A): bool {.inline.} =
  if cache.map.hasKey(key):
    result = true

func contains*[A, B](cache: var LRUCache[A, B], key: A): bool {.inline.} =
  cache.hasKey(key)


when isMainModule:
  import random, timeit, os

  randomize(128)

  timeOnce("list"):
    var s = initLRUCache[int, int](64)
    for i in 1 .. 100:
      s.put(rand(1 .. 64), rand(1 .. 126))

    echo s.list
    os.sleep(2000)
    s.put(5, 6)
    echo s.get(12)
    echo s.get(14)
    echo s.get(5)
    echo s.len
    echo s.list
