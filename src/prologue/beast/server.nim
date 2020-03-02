import httpcore, asyncdispatch

import request
import ../core/nativesettings
import ../core/context


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

# proc close*(app: Prologue) =
#   app.server.close()

# proc newPrologueServer*(reuseAddr = true, reusePort = false,
#                          maxBody = 8388608): Server =
#   newAsyncHttpServer(reuseAddr, reusePort, maxBody)
