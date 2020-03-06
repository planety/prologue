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
