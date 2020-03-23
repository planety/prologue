import ../../src/prologue
import ../../src/prologue/middlewares/middlewares
import strformat


proc upload(ctx: Context) {.async.} =
  if ctx.request.reqMethod == HttpGet:
    await ctx.staticFileResponse("upload.html", "")
  elif ctx.request.reqMethod == HttpPost:
    let file = ctx.getUploadFile("file")
    resp fmt"<html><h1>{file.filename}</h1><p>{file.body}</p></html>"

let settings = newSettings(port = Port(8000))
var app = newApp(settings, middlewares = @[debugRequestMiddleware()])
app.addRoute("/upload", upload, @[HttpGet, HttpPost])
app.run()
