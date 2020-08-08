import ../../src/prologue
import ../../src/prologue/middlewares
import strformat


proc upload(ctx: Context) {.async.} =
  if ctx.request.reqMethod == HttpGet:
    await ctx.staticFileResponse("tests/test_uploadFile/upload.html", "")
  elif ctx.request.reqMethod == HttpPost:
    let file = ctx.getUploadFile("file")
    file.save("tests/test_uploadFile")
    file.save("tests/test_uploadFile", "set.txt")
    doAssertRaises(OSError):
      file.save("not/exists/dir")
    resp fmt"<html><h1>{file.filename}</h1><p>{file.body}</p></html>"

let settings = newSettings(port = Port(8000))
var app = newApp(settings, middlewares = @[debugRequestMiddleware()])
app.addRoute("/upload", upload, @[HttpGet, HttpPost])
app.run()
