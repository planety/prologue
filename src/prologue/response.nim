import httpcore
import cookies
import times
import json
import strformat
# import mimetypes


type
  Response* = object
    httpVersion*: HttpVersion
    status*: HttpCode
    httpHeaders*: HttpHeaders
    cookies*: string
    body*: string

proc `$`*(response: Response): string =
  fmt"{response.status} {response.httpHeaders}"

proc initResponse*(httpVersion: HttpVersion, status: HttpCode,
    httpHeaders = newHttpHeaders(), body = "",
        contentTypes = "text/html; charset=UTF-8"): Response =
  httpHeaders["Content-Type"] = contentTypes
  Response(httpVersion: httpVersion, status: status, httpHeaders: httpHeaders, body: body)

proc setHeader*(response: var Response; key, value: string) =
  response.httpHeaders[key] = value

proc addHeader*(response: var Response; key, value: string) =
  response.httpHeaders.add(key, value)

proc setCookie*(response: var Response; key, value: string; expires: DateTime |
    Time; domain = ""; path = ""; noName = false; secure = false;
        httpOnly = false): string =
  response.cookies = setCookie(key, value, expires, domain, path, noName,
      secure, httpOnly)

proc abort*(status = Http401, body = ""): Response {.inline.} =
  result = initResponse(HttpVer11, status = status, body = body)

proc redirect*(url: string, status = Http301,
    body = "", delay = 0): Response {.inline.} =

  var headers = newHttpHeaders()
  if delay == 0:
    headers.add("Location", url)
  else:
    headers.add("refresh", fmt"""{delay};url="{url}"""")
  result = initResponse(HttpVer11, status = status, httpHeaders = headers, body = body)

proc error404*(status = Http404,
    body = "<h1>404 Not Found!</h1>"): Response {.inline.} =
  result = initResponse(HttpVer11, status = status, body = body)

# change later
# for example use asyncfile
proc htmlResponse*(text: string): Response {.inline.} =
  result = initResponse(HttpVer11, Http200, {
      "Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders,
      body = text)

proc plainTextResponse*(text: string): Response {.inline.} =
  initResponse(HttpVer11, Http200, {
      "Content-Type": "text/plain; charset=UTF-8"}.newHttpHeaders,
      body = text)

proc jsonResponse*(text: JsonNode): Response {.inline.} =
  initResponse(HttpVer11, Http200, {
      "Content-Type": "text/json; charset=UTF-8"}.newHttpHeaders,
      body = $text)

# Static File Response
proc staticFileResponse*(fileName, root: string, mimetype = true,
    download = false, charset = "UTF-8", headers = {
        "Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders): Response {.inline.} =
  var status = Http200

  let f = open(fileName, fmRead)
  defer: f.close()
  result = initResponse(HttpVer11, status, headers, body = f.readAll())
