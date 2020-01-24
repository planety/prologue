import strtabs

import request, response

# TODO may add app instance
type
  Context* = ref object
    request*: Request
    response*: Response

proc newContext*(request: Request, response: Response, cookies = newStringTable()): Context =
  Context(request: request, response: response)
