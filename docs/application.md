# application

## Prologue Object

Prologue object

## Create a Prologue object

Use `newApp` to get Prologue instance.

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
