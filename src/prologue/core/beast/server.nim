import httpcore


import ../dispatch
from ./request import NativeRequest
from ../nativesettings import Settings, CtxSettings
from ../context import Router, ReversedRouter, ReRouter, HandlerAsync, Event, ErrorHandlerTable

import httpbeast except Settings, Request


type
  Prologue* = ref object
    settings*: Settings
    ctxSettings*: CtxSettings
    router*: Router
    reversedRouter*: ReversedRouter
    reRouter*: ReRouter
    middlewares*: seq[HandlerAsync]
    startup*: seq[Event]
    shutdown*: seq[Event]
    errorHandlerTable*: ErrorHandlerTable

proc serve*(app: Prologue, port: Port,
  callback: proc (request: NativeRequest): Future[void] {.closure, gcsafe.},
  address = "") =
  run(callback, httpbeast.initSettings(port, address))
