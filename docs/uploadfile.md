# Upload Files

`getUploadFile` accepts the name of file in order to get the infos. The function returns the name and contents of the file. For this example, the name is "file". 

```html
<form action="upload" method="post" enctype="multipart/form-data">
  <input type="file" name="file" value="eva">
  <input type="submit" value="Submit" name="submit">
</form>
```

`getUploadFile` only works when using form parameters and HttpPost method. `Context` provides a helper function to `save` the uploadFile to disks. If you don't specify the name of the file, it will use the origin name from the client.

```nim
proc upload(ctx: Context) {.async.} =
  if ctx.request.reqMethod == HttpGet:
    await ctx.staticFileResponse("tests/local/uploadFile/upload.html", "")
  elif ctx.request.reqMethod == HttpPost:
    let file = ctx.getUploadFile("file")
    file.save("tests/assets/temp")
    file.save("tests/assets/temp", "set.txt")
    resp fmt"<html><h1>{file.filename}</h1><p>{file.body}</p></html>"
```

The full [example](https://github.com/planety/prologue/blob/devel/tests/local/uploadFile/local_uploadFile_test.nim)
