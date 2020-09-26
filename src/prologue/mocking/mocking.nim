import ../core/application


proc mockingMiddleware*(): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    ctx.handled = true

proc mockApp*(app: Prologue) =
  ## Adds mocking middleware to global middlewares.
  app.middlewares.add mockingMiddleware()

proc runOnce*(app: Prologue, request: Request) =
  ## Starts an Application.
  waitFor handleContext(app, request)
