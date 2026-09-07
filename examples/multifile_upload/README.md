# Multiple File Upload Example

This example demonstrates how to handle multiple file uploads from a single HTML input element using Prologue's new `getUploadFiles` API.

## What's New

Prologue now supports retrieving multiple files uploaded from a single input element with the `multiple` attribute. 

### New API

- **`getUploadFiles(name: string): seq[UploadFile]`**: Returns all uploaded files with the given input name
- **`getUploadFile(name: string): UploadFile`**: Returns the first uploaded file (backward compatible)

## HTML Form

```html
<form method="post" action="/upload" enctype="multipart/form-data">
    <input type="file" name="files" multiple />
    <input type="submit" value="Upload" />
</form>
```

## Handler Code

```nim
proc uploadFiles(ctx: Context) {.async.} =
  let files = ctx.getUploadFiles("files")
  
  for file in files:
    echo "Filename: ", file.filename
    echo "Size: ", file.body.len, " bytes"
    # Optionally save the file
    # file.save("uploads/")
```

## Running the Example

```bash
nim c -r examples/multifile_upload/app.nim
```

Then open your browser to `http://localhost:8080` and select multiple files to upload.
