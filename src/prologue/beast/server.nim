import httpcore, asyncdispatch

from ./request import NativeRequest
from ../core/nativesettings import Settings
from ../core/context import Router, ReversedRouter, ReRouter, HandlerAsync, Event, ErrorHandlerTable

import httpbeast except Settings, Request


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

proc appName*(app: Prologue): string {.inline.} =
  app.settings.appName

proc serve*(app: Prologue, port: Port,
  callback: proc (request: NativeRequest): Future[void] {.closure, gcsafe.},
  address = "") =
  run(callback, httpbeast.initSettings(port, address))
