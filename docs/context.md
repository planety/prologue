# Context

Context object

```nim
type
  Context* = ref object
    request*: Request
    response*: Response
    router*: Router
    reversedRouter*: ReversedRouter
    reRouter*: ReRouter
    size*: int
    first*: bool
    handled*: bool
    middlewares*: seq[HandlerAsync]
    session*: Session
    cleanedData*: StringTableRef
    attributes*: StringTableRef # for extension
```
