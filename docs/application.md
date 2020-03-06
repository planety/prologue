# application

## Prologue Object

Prologue object

```nim
type
  Prologue* = ref object
    settings*: Settings
    router*: Router
    reversedRouter*: ReversedRouter
    reRouter*: ReRouter
    middlewares*: seq[HandlerAsync]
    startup*: seq[Event]
    shutdown*: seq[Event]
    errorHandlerTable*: ErrorHandlerTable
```
## Create a Prologue object

Use `newApp` to get Prologue instance.

```nim
proc newApp*(settings: Settings, middlewares: seq[HandlerAsync] = @[],
    startup: seq[Event] = @[], shutdown: seq[Event] = @[],
        errorHandlerTable = {Http404: default404Handler,
            Http500: default500Handler}.newErrorHandlerTable)
```

### Settings

Use `newSettings` to create application settings.

### Middlewares

Register `middlewares` for the whole application.The middlewares will 
apply to every handler.

### Startup and ShutUp

Register event for startup and shutup.Support both sync and async proc.

```nim
type
  AsyncEvent* = proc(): Future[void] {.closure, gcsafe.}
  SyncEvent* = proc() {.closure, gcsafe.}
```

### Error Handler

Map status code to error handler.

