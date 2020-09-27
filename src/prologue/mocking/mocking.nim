import ../core/application


proc mockingMiddleware*(): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    ctx.handled = true
    await switch(ctx)

proc mockApp*(app: Prologue) =
  ## Adds mocking middleware to global middlewares.
  app.middlewares.add mockingMiddleware()

proc runOnce*(app: Prologue, request: Request): Context =
  ## Starts an Application.
  result = newContext(request, initResponse(HttpVer11, Http200), app.gScope)
  waitFor handleContext(app, result)

proc runOnce*(app: Prologue, ctx: Context) =
  ## Starts an Application.
  waitFor handleContext(app, ctx)
