import strtabs, json
from asynchttpserver import newAsyncHttpServer, serve, close, AsyncHttpServer


import asyncdispatch
from ./request import NativeRequest
from ../nativesettings import Settings, CtxSettings, getOrDefault
from ../context import Router, ReversedRouter, ReRouter, HandlerAsync,
    Event, ErrorHandlerTable, GlobalScope


type
  Server* = AsyncHttpServer

  Prologue* = ref object
    server: Server
    gScope*: GlobalScope
    middlewares*: seq[HandlerAsync]
    startup*: seq[Event]
    shutdown*: seq[Event]
    errorHandlerTable*: ErrorHandlerTable


proc serve*(app: Prologue, port: Port,
            callback: proc (request: NativeRequest): Future[void] {.closure, gcsafe.},
            address = "") {.inline.} =
  waitFor app.server.serve(port, callback, address)

proc newPrologueServer*(reuseAddr = true, reusePort = false,
                        maxBody = 8388608): Server {.inline.} =
  newAsyncHttpServer(reuseAddr, reusePort, maxBody)

proc newPrologue*(settings: Settings, ctxSettings: CtxSettings, router: Router,
                  reversedRouter: ReversedRouter, reRouter: ReRouter,
                  middlewares: seq[HandlerAsync], startup: seq[Event], shutdown: seq[Event],
                  errorHandlerTable: ErrorHandlerTable, appData: StringTableRef): Prologue {.inline.} =
  Prologue(server: newPrologueServer(true, settings.getOrDefault(
           "reusePort").getBool), gScope: GlobalScope(settings: settings, ctxSettings: ctxSettings, router: router, 
           reversedRouter: reversedRouter, reRouter: reRouter, appData: appData),
           middlewares: middlewares, startup: startup, shutdown: shutdown,
           errorHandlerTable: errorHandlerTable)
