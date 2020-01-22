import httpcore
import mimetypes


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

# Static File Response
proc staticFileResponse*(fileName, root: string, mimetype = true,
    download = false, charset = "UTF-8", headers: HttpHeaders = nil): Response =
  var status = Http200
  var headers = headers
  if headers == nil:
    headers = {"Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders

  let f = open(fileName, fmRead)
  defer: f.close()
  result = initResponse(HttpVer11, status, headers, body = f.readAll())
