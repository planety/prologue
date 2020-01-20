import strtabs

import request, response


type
  Context* = ref object
    request*: Request
    response*: Response
    params*: StringTableRef