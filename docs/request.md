# Request

Request object

```nim
type
  Request* = object
    nativeRequest: NativeRequest
    url: Uri
    cookies*: StringTableRef
    postParams*: StringTableRef
    queryParams*: StringTableRef # Only use queryParams for all url params
    formParams*: FormPart
    pathParams*: StringTableRef
    settings*: Settings
```