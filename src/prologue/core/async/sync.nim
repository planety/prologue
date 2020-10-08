#            Chronos synchronization primitives
#
#           (c) Copyright 2018-Present Eugene Kabanov
#  (c) Copyright 2018-Present Status Research & Development GmbH
#
#                Licensed under either of
#    Apache License, version 2.0, (LICENSE-APACHEv2)
#                MIT license (LICENSE-MIT)
# 
#             Copyright 2020 Zeshen Xing
#


## This module implements some core synchronization primitives
import std/[sequtils, deques, asyncdispatch]


type
  AsyncLock* = ref object of RootRef
    ## A primitive lock is a synchronization primitive that is not owned by
    ## a particular coroutine when locked. A primitive lock is in one of two
    ## states, ``locked`` or ``unlocked``.
    ##
    ## When more than one coroutine is blocked in ``acquire()`` waiting for
    ## the state to turn to unlocked, only one coroutine proceeds when a
    ## ``release()`` call resets the state to unlocked; first coroutine which
    ## is blocked in ``acquire()`` is being processed.
    locked: bool
    acquired: bool
    waiters: seq[Future[void]]

  AsyncEvent* = ref object of RootRef
    ## A primitive event object.
    ##
    ## An event manages a flag that can be set to `true` with the ``fire()``
    ## procedure and reset to `false` with the ``clear()`` procedure.
    ## The ``wait()`` coroutine blocks until the flag is `false`.
    ##
    ## If more than one coroutine blocked in ``wait()`` waiting for event
    ## state to be signalled, when event get fired, then all coroutines
    ## continue proceeds in order, they have entered waiting state.
    flag: bool
    waiters: seq[Future[void]]

  AsyncQueue*[T] = ref object of RootRef
    ## A queue, useful for coordinating producer and consumer coroutines.
    ##
    ## If ``maxsize`` is less than or equal to zero, the queue size is
    ## infinite. If it is an integer greater than ``0``, then "await put()"
    ## will block when the queue reaches ``maxsize``, until an item is
    ## removed by "await get()".
    getters: seq[Future[void]]
    putters: seq[Future[void]]
    queue: Deque[T]
    maxsize: int

  AsyncQueueEmptyError* = object of CatchableError
    ## ``AsyncQueue`` is empty.
  AsyncQueueFullError* = object of CatchableError
    ## ``AsyncQueue`` is full.
  AsyncLockError* = object of CatchableError
    ## ``AsyncLock`` is either locked or unlocked.

proc newAsyncLock*(): AsyncLock =
  ## Creates new asynchronous lock ``AsyncLock``.
  ##
  ## Lock is created in the unlocked state. When the state is unlocked,
  ## ``acquire()`` changes the state to locked and returns immediately.
  ## When the state is locked, ``acquire()`` blocks until a call to
  ## ``release()`` in another coroutine changes it to unlocked.
  ##
  ## The ``release()`` procedure changes the state to unlocked and returns
  ## immediately.

  # Workaround for callSoon() not worked correctly before
  # getGlobalDispatcher() call.
  discard getGlobalDispatcher()
  AsyncLock(waiters: newSeq[Future[void]](), locked: false, acquired: false)

proc wakeUpFirst(lock: AsyncLock): bool {.inline.} =
  ## Wake up the first waiter if it isn't done.
  var i = 0
  var res = false
  while i < len(lock.waiters):
    var waiter = lock.waiters[i]
    inc(i)
    if not waiter.finished:
      waiter.complete()
      res = true
      break
  if i > 0:
    lock.waiters.delete(0, i - 1)
  res

proc acquire*(lock: AsyncLock) {.async.} =
  ## Acquire a lock ``lock``.
  ##
  ## This procedure blocks until the lock ``lock`` is unlocked, then sets it
  ## to locked and returns.
  if not lock.locked:
    lock.acquired = true
    lock.locked = true
  else:
    var w = newFuture[void]("AsyncLock.acquire")
    lock.waiters.add(w)
    await w
    lock.acquired = true
    lock.locked = true

proc locked*(lock: AsyncLock): bool =
  ## Return `true` if the lock ``lock`` is acquired, `false` otherwise.
  lock.locked

proc release*(lock: AsyncLock) =
  ## Release a lock ``lock``.
  ##
  ## When the ``lock`` is locked, reset it to unlocked, and return. If any
  ## other coroutines are blocked waiting for the lock to become unlocked,
  ## allow exactly one of them to proceed.
  if lock.locked:
    # We set ``lock.locked`` to ``false`` only when there no active waiters.
    # If active waiters are present, then ``lock.locked`` will be set to `true`
    # in ``acquire()`` procedure's continuation.
    if not lock.acquired:
      raise newException(AsyncLockError, "AsyncLock was already released!")
    else:
      lock.acquired = false
      if not lock.wakeUpFirst:
        lock.locked = false
  else:
    raise newException(AsyncLockError, "AsyncLock is not acquired!")

proc newAsyncEvent*(): AsyncEvent =
  ## Creates new asyncronous event ``AsyncEvent``.
  ##
  ## An event manages a flag that can be set to `true` with the `fire()`
  ## procedure and reset to `false` with the `clear()` procedure.
  ## The `wait()` procedure blocks until the flag is `true`. The flag is
  ## initially `false`.

  # Workaround for callSoon() not worked correctly before
  # getGlobalDispatcher() call.
  discard getGlobalDispatcher()
  AsyncEvent(waiters: newSeq[Future[void]](), flag: false)

proc wait*(event: AsyncEvent): Future[void] =
  ## Block until the internal flag of ``event`` is `true`.
  ## If the internal flag is `true` on entry, return immediately. Otherwise,
  ## block until another task calls `fire()` to set the flag to `true`,
  ## then return.
  var waiter = newFuture[void]("AsyncEvent.wait")
  if not(event.flag):
    event.waiters.add(waiter)
  else:
    complete(waiter)
  waiter

proc fire*(event: AsyncEvent) =
  ## Set the internal flag of ``event`` to `true`. All tasks waiting for it
  ## to become `true` are awakened. Task that call `wait()` once the flag is
  ## `true` will not block at all.
  if not event.flag:
    event.flag = true
    for fut in event.waiters:
      if not fut.finished: # Could have been cancelled
        complete(fut)
    event.waiters.setLen(0)

proc clear*(event: AsyncEvent) =
  ## Reset the internal flag of ``event`` to `false`. Subsequently, tasks
  ## calling `wait()` will block until `fire()` is called to set the internal
  ## flag to `true` again.
  event.flag = false

proc isSet*(event: AsyncEvent): bool =
  ## Return `true` if and only if the internal flag of ``event`` is `true`.
  event.flag

proc newAsyncQueue*[T](maxsize: int = 0): AsyncQueue[T] =
  ## Creates a new asynchronous queue ``AsyncQueue``.

  # Workaround for callSoon() not worked correctly before
  # getGlobalDispatcher() call.
  discard getGlobalDispatcher()
  AsyncQueue[T](
    getters: newSeq[Future[void]](),
    putters: newSeq[Future[void]](),
    queue: initDeque[T](),
    maxsize: maxsize
  )

proc wakeupNext(waiters: var seq[Future[void]]) {.inline.} =
  var i = 0
  while i < len(waiters):
    var waiter = waiters[i]
    inc i

    if not waiter.finished:
      complete(waiter)
      break

  if i > 0:
    waiters.delete(0, i - 1)

proc full*[T](aq: AsyncQueue[T]): bool {.inline.} =
  ## Return ``true`` if there are ``maxsize`` items in the queue.
  ##
  ## Note: If the ``aq`` was initialized with ``maxsize = 0`` (default),
  ## then ``full()`` is never ``true``.
  if aq.maxsize <= 0:
    false
  else:
    (len(aq.queue) >= aq.maxsize)

proc empty*[T](aq: AsyncQueue[T]): bool {.inline.} =
  ## Return ``true`` if the queue is empty, ``false`` otherwise.
  (len(aq.queue) == 0)

proc addFirstNoWait*[T](aq: AsyncQueue[T], item: T) =
  ## Put an item ``item`` to the beginning of the queue ``aq`` immediately.
  ##
  ## If queue ``aq`` is full, then ``AsyncQueueFullError`` exception raised.
  if aq.full:
    raise newException(AsyncQueueFullError, "AsyncQueue is full!")
  aq.queue.addFirst(item)
  aq.getters.wakeupNext()

proc addLastNoWait*[T](aq: AsyncQueue[T], item: T) =
  ## Put an item ``item`` at the end of the queue ``aq`` immediately.
  ##
  ## If queue ``aq`` is full, then ``AsyncQueueFullError`` exception raised.
  if aq.full:
    raise newException(AsyncQueueFullError, "AsyncQueue is full!")
  aq.queue.addLast(item)
  aq.getters.wakeupNext()

proc popFirstNoWait*[T](aq: AsyncQueue[T]): T =
  ## Get an item from the beginning of the queue ``aq`` immediately.
  ##
  ## If queue ``aq`` is empty, then ``AsyncQueueEmptyError`` exception raised.
  if aq.empty:
    raise newException(AsyncQueueEmptyError, "AsyncQueue is empty!")
  let res = aq.queue.popFirst()
  aq.putters.wakeupNext()
  res

proc popLastNoWait*[T](aq: AsyncQueue[T]): T =
  ## Get an item from the end of the queue ``aq`` immediately.
  ##
  ## If queue ``aq`` is empty, then ``AsyncQueueEmptyError`` exception raised.
  if aq.empty:
    raise newException(AsyncQueueEmptyError, "AsyncQueue is empty!")
  let res = aq.queue.popLast()
  aq.putters.wakeupNext()
  res

proc addFirst*[T](aq: AsyncQueue[T], item: T) {.async.} =
  ## Put an ``item`` to the beginning of the queue ``aq``. If the queue is full,
  ## wait until a free slot is available before adding item.
  while aq.full:
    var putter = newFuture[void]("AsyncQueue.addFirst")
    aq.putters.add(putter)
    try:
      await putter
    except CatchableError as exc:
      if not aq.full and not putter.cancelled:
        aq.putters.wakeupNext()
      raise exc
  aq.addFirstNoWait(item)

proc addLast*[T](aq: AsyncQueue[T], item: T) {.async.} =
  ## Put an ``item`` to the end of the queue ``aq``. If the queue is full,
  ## wait until a free slot is available before adding item.
  while aq.full:
    var putter = newFuture[void]("AsyncQueue.addLast")
    aq.putters.add(putter)
    try:
      await putter
    except CatchableError as exc:
      if not aq.full and not putter.cancelled:
        aq.putters.wakeupNext()
      raise exc
  aq.addLastNoWait(item)

proc popFirst*[T](aq: AsyncQueue[T]): Future[T] {.async.} =
  ## Remove and return an ``item`` from the beginning of the queue ``aq``.
  ## If the queue is empty, wait until an item is available.
  while aq.empty:
    var getter = newFuture[void]("AsyncQueue.popFirst")
    aq.getters.add(getter)
    try:
      await getter
    except CatchableError as exc:
      if not aq.empty and not getter.cancelled:
        aq.getters.wakeupNext()
      raise exc
  return aq.popFirstNoWait()

proc popLast*[T](aq: AsyncQueue[T]): Future[T] {.async.} =
  ## Remove and return an ``item`` from the end of the queue ``aq``.
  ## If the queue is empty, wait until an item is available.
  while aq.empty:
    var getter = newFuture[void]("AsyncQueue.popLast")
    aq.getters.add(getter)
    try:
      await getter
    except CatchableError as exc:
      if not aq.empty and not getter.cancelled:
        aq.getters.wakeupNext()
      raise exc
  return aq.popLastNoWait()

proc putNoWait*[T](aq: AsyncQueue[T], item: T) {.inline.} =
  ## Alias of ``addLastNoWait()``.
  aq.addLastNoWait(item)

proc getNoWait*[T](aq: AsyncQueue[T]): T {.inline.} =
  ## Alias of ``popFirstNoWait()``.
  aq.popFirstNoWait()

proc put*[T](aq: AsyncQueue[T], item: T): Future[void] {.inline.} =
  ## Alias of ``addLast()``.
  aq.addLast(item)

proc get*[T](aq: AsyncQueue[T]): Future[T] {.inline.} =
  ## Alias of ``popFirst()``.
  aq.popFirst()

proc clear*[T](aq: AsyncQueue[T]) {.inline.} =
  ## Clears all elements of queue ``aq``.
  aq.queue.clear()

proc len*[T](aq: AsyncQueue[T]): int {.inline.} =
  ## Return the number of elements in ``aq``.
  len(aq.queue)

proc size*[T](aq: AsyncQueue[T]): int {.inline.} =
  ## Return the maximum number of elements in ``aq``.
  len(aq.maxsize)

proc `[]`*[T](aq: AsyncQueue[T], i: Natural) : T {.inline.} =
  ## Access the i-th element of ``aq`` by order from first to last.
  ## ``aq[0]`` is the first element, ``aq[^1]`` is the last element.
  aq.queue[i]

proc `[]`*[T](aq: AsyncQueue[T], i: BackwardsIndex) : T {.inline.} =
  ## Access the i-th element of ``aq`` by order from first to last.
  ## ``aq[0]`` is the first element, ``aq[^1]`` is the last element.
  aq.queue[len(aq.queue) - int(i)]

proc `[]=`* [T](aq: AsyncQueue[T], i: Natural, item: T) {.inline.} =
  ## Change the i-th element of ``aq``.
  aq.queue[i] = item

proc `[]=`* [T](aq: AsyncQueue[T], i: BackwardsIndex, item: T) {.inline.} =
  ## Change the i-th element of ``aq``.
  aq.queue[len(aq.queue) - int(i)] = item

iterator items*[T](aq: AsyncQueue[T]): T {.inline.} =
  ## Yield every element of ``aq``.
  for item in aq.queue.items():
    yield item

iterator mitems*[T](aq: AsyncQueue[T]): var T {.inline.} =
  ## Yield every element of ``aq``.
  for mitem in aq.queue.mitems():
    yield mitem

iterator pairs*[T](aq: AsyncQueue[T]): tuple[key: int, val: T] {.inline.} =
  ## Yield every (position, value) of ``aq``.
  for pair in aq.queue.pairs():
    yield pair

proc contains*[T](aq: AsyncQueue[T], item: T): bool {.inline.} =
  ## Return true if ``item`` is in ``aq`` or false if not found. Usually used
  ## via the ``in`` operator.
  for e in aq.queue.items():
    if e == item: return true
  return false

proc `$`*[T](aq: AsyncQueue[T]): string =
  ## Turn an async queue ``aq`` into its string representation.
  var res = "["
  for item in aq.queue.items():
    if len(res) > 1: res.add(", ")
    res.addQuoted(item)
  res.add("]")
  res
