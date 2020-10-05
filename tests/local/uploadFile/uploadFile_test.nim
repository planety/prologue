import ../../../src/prologue
import ../../../src/prologue/middlewares
import strformat
import json


proc upload(ctx: Context) {.async.} =
  if ctx.request.reqMethod == HttpGet:
    await ctx.staticFileResponse("tests/local/uploadFile/upload.html", "")
  elif ctx.request.reqMethod == HttpPost:
    let file = ctx.getUploadFile("file")
    file.save("tests/assets/temp")
    file.save("tests/assets/temp", "set.txt")
    doAssertRaises(OSError):
      file.save("not/exists/dir")
    resp fmt"<html><h1>{file.filename}</h1><p>{file.body}</p></html>"

let settings = newSettings(port = Port(8080), data = %* {getServerSettingsNameOrKey("max_body"): 1000})
var app = newApp(settings, middlewares = @[debugRequestMiddleware()])
app.addRoute("/upload", upload, @[HttpGet, HttpPost])
app.run()
