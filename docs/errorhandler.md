# Error Handler

## User-defined error pages

When web application encounters some unexpected situations, it may send 404 response to the client.
You may want to use user-defined 404 pages, then you can use `resp` to return 404 response. 


```nim
proc hello(ctx: Context) {.async.} =
  resp "Something is wrong, please retry.", Http404
```
