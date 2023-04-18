import std/[strtabs, json, asyncdispatch]
from std/asynchttpserver import newAsyncHttpServer, serve, close, AsyncHttpServer

from ./request import NativeRequest
from ../nativesettings import Settings, CtxSettings, `[]`
from ../context import Router, ReversedRouter, ReRouter, HandlerAsync,
          Event, ErrorHandlerTable, GlobalScope, execEvent


type
  Server* = AsyncHttpServer

  Prologue* = ref object
    server: Server
    gScope*: GlobalScope
    middlewares*: seq[HandlerAsync]
    startup*: seq[Event]
    shutdown*: seq[Event]
    errorHandlerTable*: ErrorHandlerTable


proc execStartupEvent*(app: Prologue) =
  for event in app.startup:
    execEvent(event)

proc serveAsync*(app: Prologue,
            callback: proc (request: NativeRequest): Future[void] {.closure, gcsafe.},
           ) {.inline, async.} =
  ## Serves a new web application.
  await app.server.serve(app.gScope.settings.port, callback, app.gScope.settings.address)

proc serve*(app: Prologue,
            callback: proc (request: NativeRequest): Future[void] {.closure, gcsafe.},
           ) {.inline.} =
  ## Serves a new web application.
  waitFor serveAsync(app, callback)

func newPrologueServer(reuseAddr = true, reusePort = false,
                       maxBody = 8388608): Server {.inline.} =
  newAsyncHttpServer(reuseAddr, reusePort, maxBody)

func newPrologue*(
  settings: Settings, ctxSettings: CtxSettings, router: Router,
  reversedRouter: ReversedRouter, reRouter: ReRouter,
  middlewares: openArray[HandlerAsync], startup: openArray[Event], 
  shutdown: openArray[Event], errorHandlerTable: ErrorHandlerTable, 
  appData: StringTableRef
): Prologue {.inline.} =
  Prologue(server: newPrologueServer(true, settings.reusePort, 
                                    settings["prologue"].getOrDefault("maxBody").getInt(8388608)), 
           gScope: GlobalScope(settings: settings, ctxSettings: ctxSettings, router: router, 
           reversedRouter: reversedRouter, reRouter: reRouter, appData: appData),
           middlewares: @middlewares, startup: @startup, shutdown: @shutdown,
           errorHandlerTable: errorHandlerTable)
