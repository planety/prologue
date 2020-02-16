import lists

type
  CachedPolicy* = enum
    LRU, LFU, FIFO, LRUFILE, LFUFILE

  CachedInfo* = tuple
    hits: int
    misses: int
    maxSize: int

  KeyPair*[A, B] = tuple
    keyPart: A
    valuePart: B

  LFUPair*[A, B] = tuple
    keyPart: A
    valuePart: B
    hits: int

  CachedKeyPair*[A, B] = DoublyLinkedList[KeyPair[A, B]]
  MapValue*[A, B] = DoublyLinkedNode[KeyPair[A, B]]
