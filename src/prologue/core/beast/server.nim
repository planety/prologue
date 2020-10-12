import std/[strtabs, json, asyncdispatch]

from ./request import NativeRequest
from ../nativesettings import Settings, CtxSettings, `[]`
from ../context import Router, ReversedRouter, ReRouter, HandlerAsync,
    Event, ErrorHandlerTable, GlobalScope, execEvent

import pkg/httpx except Settings, Request


type
  Prologue* = ref object
    gScope*: GlobalScope
    middlewares*: seq[HandlerAsync]
    startup*: seq[Event]
    shutdown*: seq[Event]
    errorHandlerTable*: ErrorHandlerTable
    startupClosure: proc () {.closure, gcsafe.}

proc execStartupEvent*(app: Prologue) =
  proc doStartup() {.gcsafe.} =
    for event in app.startup:
      execEvent(event)

  app.startupClosure = doStartup

proc serve*(app: Prologue,
            callback: proc (request: NativeRequest): Future[void] {.closure, gcsafe.},
           ) {.inline.} =
  ## Serves a new web application.
  run(callback, httpx.initSettings(app.gScope.settings.port, app.gScope.settings.address,
                app.gScope.settings["prologue"].getOrDefault("numThreads").getInt(0),
                app.startupClosure)
                )

func newPrologue*(settings: Settings, ctxSettings: CtxSettings, router: Router,
                  reversedRouter: ReversedRouter, reRouter: ReRouter, middlewares: openArray[HandlerAsync], 
                  startup: openArray[Event], shutdown: openArray[Event],
                  errorHandlerTable: ErrorHandlerTable, appData: StringTableRef): Prologue {.inline.} =
  ## Creates a new application instance.
  Prologue(gScope: GlobalScope(settings: settings, ctxSettings: ctxSettings, router: router, 
           reversedRouter: reversedRouter, reRouter: reRouter, appData: appData),
           middlewares: @middlewares, startup: @startup, shutdown: @shutdown,
           errorHandlerTable: errorHandlerTable)
