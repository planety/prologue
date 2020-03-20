import ../../src/prologue
import strformat


proc upload(ctx: Context) {.async.} =
  if ctx.request.reqMethod == HttpGet:
    await ctx.staticFileResponse("upload.html", "")
  elif ctx.request.reqMethod == HttpPost:
    let file = ctx.getUploadFile("file")
    resp fmt"<html><h1>{file.filename}</h1><p>{file.body}</p></html>"

let settings = newSettings()
var app = newApp(settings)
app.addRoute("/upload", upload, @[HttpGet, HttpPost])
app.run()
