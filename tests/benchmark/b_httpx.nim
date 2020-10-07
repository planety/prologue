import options, json

import httpx, asyncdispatch

proc onRequest(req: Request): Future[void] =
  if req.httpMethod == some(HttpGet):
    case req.path.get
    of "/json":
      const data = $(%*{"message": "Hello, World!"})
      req.send(Http200, data)
    of "/hello":
      const data = "Hello, World!"
      const headers = "Content-Type: text/plain"
      req.send(Http200, data, headers)
    else:
      req.send(Http404)

run(onRequest)