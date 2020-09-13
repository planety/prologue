import asynchttpserver, asyncdispatch, json

var server = newAsyncHttpServer()


proc onRequest(req: Request): Future[void] {.async, gcsafe.} =
  if req.reqMethod == HttpGet:
    case req.url.path
    of "/json":
      const data = $(%*{"message": "Hello, World!"})
      await req.respond(Http200, data)
    of "/hello":
      const data = "Hello, World!"
      let headers = newHttpHeaders([("Content-Type","text/plain")])
      await req.respond(Http200, data, headers)
    else:
      await req.respond(Http404, "")

waitFor server.serve(Port(8080), onRequest)
# 13000