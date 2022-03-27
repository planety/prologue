# Event

`Prologue` supports both `startup` and `shutdown` events. `startup` events will be only executed once for each thread. In contrast, `shutdown` events will be executed once after the main loop.

Let's first look at the structure of `Event`, you can see that `Event` supports both synchronous and asynchronous closure function pointers.

```nim
type
  AsyncEvent* = proc(): Future[void] {.closure, gcsafe.}
  SyncEvent* = proc() {.closure, gcsafe.}

  Event* = object
    case async*: bool
    of true:
      asyncHandler*: AsyncEvent
    of false:
      syncHandler*: SyncEvent
```

You can use `initEvent` and pass function pointers to create `Event`.

```nim
proc initEvent*(handler: AsyncEvent): Event {.inline.} =
  Event(async: true, asyncHandler: handler)

proc initEvent*(handler: SyncEvent): Event {.inline.} =
  Event(async: false, syncHandler: handler)
```

`newApp` has `startup` and `shutdown` parameters. You can pass a sequence of events to `newApp`.

```nim
proc newApp*(settings: Settings, middlewares: sink seq[HandlerAsync] = @[],
             startup: seq[Event] = @[], shutdown: seq[Event] = @[],
             errorHandlerTable = DefaultErrorHandler,
             appData = newStringTable(mode = modeCaseSensitive)): Prologue =
```

Here is an [example](https://github.com/planety/prologue/tree/devel/examples/helloworld) for a `startup` event (A `shutdown` event has the same usage as a `startup` event).

```nim
proc setLoggingLevel() =
  addHandler(newConsoleLogger())
  logging.setLogFilter(lvlInfo)


let 
  event = initEvent(setLoggingLevel)

var
  app = newApp(settings = settings, startup = @[event])
```
