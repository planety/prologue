import strtabs

from ./types import FormPart


when defined(windows) or defined(usestd):
  import asynchttpserver
  type NativeRequest* = asynchttpserver.Request
else:
  import httpBeast
  type NativeRequest* = httpBeast.Request


type
  Request* = object
    nativeRequest*: NativeRequest
    cookies*: StringTableRef
    postParams*: StringTableRef
    queryParams*: StringTableRef # Only use queryParams for all url params
    formParams*: FormPart
    pathParams*: StringTableRef
