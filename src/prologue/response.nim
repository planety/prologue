import httpcore
import cookies
import times
import json
import strformat


type
  Response* = object
    httpVersion*: HttpVersion
    status*: HttpCode
    httpHeaders*: HttpHeaders
    cookies*: string
    body*: string

proc `$`*(response: Response): string =
  fmt"{response.status} {response.httpHeaders}"

proc initResponse*(httpVersion: HttpVersion, status: HttpCode, httpHeaders =
    {"Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders,
        body = ""): Response =
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
      "Content-Type": "text/plain"}.newHttpHeaders,
      body = text)

proc jsonResponse*(text: JsonNode): Response {.inline.} =
  initResponse(HttpVer11, Http200, {
      "Content-Type": "application/json"}.newHttpHeaders,
      body = $text)
