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

# change later
# for example use asyncfile
proc htmlResponse*(fileName: string): Response =
  let f = open(fileName, fmRead)
  defer: f.close()
  result = initResponse(HttpVer11, Http200, {
      "Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders,
      body = f.readAll())
