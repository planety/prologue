import logging

import ../../src/prologue
import ../../src/prologue/middlewares/auth
import ../../src/prologue/middlewares/utils


proc verify(ctx: Context, username, password: string): bool =
  if username == "prologue" and password == "starlight":
    result = true
  else:
    result = false

proc home(ctx: Context) {.async.} =
  debug ctx.ctxData.getOrDefault("basic_auth_username")
  debug ctx.ctxData.getOrDefault("basic_auth_password")
  resp "You logged in."


let settings = newSettings()
var app = newApp(settings)
app.addRoute("/home", home, middlewares = @[debugRequestMiddleware(), basicAuthMiddleware(realm = "home", verify)])
app.run()
