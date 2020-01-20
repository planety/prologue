import httpcore


type
  Response* = object
    httpVersion*: HttpVersion
    status*: HttpCode
    httpHeaders*: HttpHeaders
    body*: string

proc initResponse*(httpVersion: HttpVersion, status: HttpCode,
    httpHeaders = newHttpHeaders(), body = ""): Response =
  Response(httpVersion: httpVersion, status: status, httpHeaders: httpHeaders, body: body)
