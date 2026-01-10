import ../../src/prologue
import std/strformat

proc uploadForm(ctx: Context) {.async.} =
  ## Serve the HTML form for uploading multiple files
  await ctx.staticFileResponse("examples/multifile_upload/upload.html", "")

proc uploadFiles(ctx: Context) {.async.} =
  ## Handle multiple file uploads from a single input element
  let files = ctx.getUploadFiles("files")
  
  var response = "<html><head><title>Upload Results</title></head><body>"
  response.add("<h1>Uploaded Files</h1>")
  response.add(fmt"<p>Total files uploaded: {files.len}</p>")
  response.add("<ul>")
  
  for i, file in files:
    response.add(fmt"<li>File {i+1}: {file.filename} ({file.body.len} bytes)</li>")
    # Optionally save each file
    # file.save("uploads/")
  
  response.add("</ul>")
  response.add("<a href='/'>Upload more files</a>")
  response.add("</body></html>")
  
  resp response

proc main() =
  let settings = newSettings()
  var app = newApp(settings)
  
  app.get("/", uploadForm)
  app.post("/upload", uploadFiles)
  
  app.run()

when isMainModule:
  main()
