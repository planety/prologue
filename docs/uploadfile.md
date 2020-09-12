# Upload Files

`getUploadFile` accepts the name of file input(HTNL) to get the info of file. The function returns the name and contents of the file. For this example, the name is "file". 

```html
<form action="upload" method="post" enctype="multipart/form-data">
  <input type="file" name="file" value="eva">
  <input type="submit" value="Submit" name="submit">
</form>
```

`getUploadFile` only works when you use form parameters and HttpPost method. It provides a helper function to save the uploadFile to disks. If you don't specify the name of the file, it will use the origin name from user.

```nim
proc upload(ctx: Context) {.async.} =
  if ctx.request.reqMethod == HttpGet:
    await ctx.staticFileResponse("tests/test_uploadFile/upload.html", "")
  elif ctx.request.reqMethod == HttpPost:
    let file = ctx.getUploadFile("file")
    file.save("tests/test_uploadFile")
    file.save("tests/test_uploadFile", "set.txt")
    resp fmt"<html><h1>{file.filename}</h1><p>{file.body}</p></html>"
```

The full [example](https://github.com/planety/prologue/blob/master/tests/test_uploadFile)
