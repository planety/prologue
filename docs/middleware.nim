import logging
import prologue
import prologue/middlewares/middlewares


proc hello(ctx: Context) {.async.} =
  discard

proc myDebugRequestMiddleware*(appName = "Starlight"): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    logging.info "debugRequestMiddleware->begin"
    # do something before
    await switch(ctx)
    # do something after
    logging.info "debugRequestMiddleware->End"


var
  settings = newSettings()
  app = newApp(settings = settings, middlewares = @[myDebugRequestMiddleware()])


app.addRoute("/", hello, HttpGet, middlewares = @[myDebugRequestMiddleware()])
