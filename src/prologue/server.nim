import httpcore
import asyncdispatch
import asynchttpserver except Request
import request, route
import nativesettings


type
  Server* = AsyncHttpServer

  Prologue* = object
    server*: Server
    settings*: Settings
    router*: Router
    middlewares*: seq[MiddlewareHandler]


proc appName*(app: Prologue): string {.inline.} =
  app.settings.appName

proc serve*(app: Prologue, port: Port,
  callback: proc (request: NativeRequest): Future[void] {.closure, gcsafe.},
  address = "") {.async.} =
  await app.server.serve(port, callback, address)

proc close*(app: Prologue) =
  app.server.close()

proc newPrologueServer*(reuseAddr = true, reusePort = false,
                         maxBody = 8388608): Server =
  newAsyncHttpServer(reuseAddr, reusePort, maxBody)
