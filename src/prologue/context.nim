import strtabs

import request, response

# TODO may add app instance
type
  Context* = ref object
    request*: Request
    response*: Response
    params*: StringTableRef
