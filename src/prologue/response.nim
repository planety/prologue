import httpcore
import cookies
import times
# import mimetypes


type
  Response* = object
    httpVersion*: HttpVersion
    status*: HttpCode
    httpHeaders*: HttpHeaders
    cookies*: string
    body*: string

proc initResponse*(httpVersion: HttpVersion, status: HttpCode,
    httpHeaders = newHttpHeaders(), body = ""): Response =
  Response(httpVersion: httpVersion, status: status, httpHeaders: httpHeaders, body: body)

proc setHeader*(response: var Response; key, value: string) =
  response.httpHeaders[key] = value

proc addHeader*(response: var Response; key, value: string) =
  response.httpHeaders.add(key, value)

proc setCookie*(response: var Response; key, value: string; expires: DateTime |
    Time; domain = ""; path = ""; noName = false; secure = false; httpOnly = false): string =
  response.cookies = setCookie(key, value, expires, domain, path, noName, secure, httpOnly)

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
