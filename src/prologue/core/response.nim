import httpcore
import times, json, strformat, options, macros

import cookiejar


type
  Response* = object
    httpVersion*: HttpVersion
    code*: HttpCode
    headers*: HttpHeaders
    body*: string


proc `$`*(response: Response): string =
  fmt"{response.code} {response.headers}"

proc initResponse*(httpVersion: HttpVersion, code: HttpCode, headers =
                   {"Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders,
                   body = ""): Response =
  Response(httpVersion: httpVersion, code: code, headers: headers, body: body)

proc hasHeader*(response: Response, key: string): bool {.inline.} =
  response.headers.hasKey(key)

proc setHeader*(response: var Response, key, value: string) {.inline.} =
  response.headers[key] = value

proc setHeader*(response: var Response, key: string, value: sink seq[string]) {.inline.} =
  response.headers[key] = value

proc addHeader*(response: var Response, key, value: string) {.inline.} =
  response.headers.add(key, value)

proc setCookie*(response: var Response, key, value: string, expires = "",
                maxAge: Option[int] = none(int), domain = "", path = "", secure = false,
                httpOnly = false, sameSite = Lax) {.inline.} =
  let cookies = initCookie(key, value, expires, maxAge, domain, 
                           path, secure, httpOnly, sameSite)
  response.addHeader("Set-Cookie", $cookies)

proc setCookie*(response: var Response, key, value: string, expires: DateTime|Time, 
                maxAge: Option[int] = none(int), domain = "",
                path = "", secure = false, httpOnly = false, sameSite = Lax) {.inline.} =
  let cookies = initCookie(key, value, expires, maxAge, domain, 
                          path, secure, httpOnly, sameSite)
  response.addHeader("Set-Cookie", $cookies)

proc deleteCookie*(response: var Response, key: string, value = "", path = "",
                   domain = "") {.inline.} =
  response.setCookie(key, value, expires = secondsForward(0), maxAge = some(0),
                     path = path, domain = domain)

proc abort*(code = Http401, body = "", headers = newHttpHeaders(),
            version = HttpVer11): Response {.inline.} =
  result = initResponse(version, code = code, body = body,
                        headers = headers)

proc redirect*(url: string, code = Http301,
               body = "", delay = 0, headers = newHttpHeaders(),
               version = HttpVer11): Response {.inline.} =
  ## redirect to new url.
  if delay == 0:
    headers.add("Location", url)
  else:
    headers.add("refresh", &"{delay};url=\"{url}\"")
  result = initResponse(version, code = code, headers = headers, body = body)

proc error404*(code = Http404,
               body = "<h1>404 Not Found!</h1>", headers = newHttpHeaders(),
               version = HttpVer11): Response {.inline.} =
  result = initResponse(version, code = code, body = body, headers = headers)

proc htmlResponse*(text: string, code = Http200, headers = newHttpHeaders(),
                   version = HttpVer11): Response {.inline.} =
  ## Content-Type": "text/html; charset=UTF-8
  headers["Content-Type"] = "text/html; charset=UTF-8"
  result = initResponse(version, code, headers, body = text)

proc plainTextResponse*(text: string, code = Http200,
                        headers = newHttpHeaders(), version = HttpVer11): Response {.inline.} =
  ## Content-Type": "text/plain
  headers["Content-Type"] = "text/plain"
  result = initResponse(version, code, headers, body = text)

proc jsonResponse*(text: JsonNode, code = Http200, headers = newHttpHeaders(),
    version = HttpVer11): Response {.inline.} =
  ## Content-Type": "application/json
  headers["Content-Type"] = "text/json"
  result = initResponse(version, code, headers, body = $text)

macro resp*(body: string, code = Http200) =
  ## handy to make ctx's response
  var ctx = ident"ctx"

  result = quote do:
    let response = initResponse(httpVersion = HttpVer11, code = `code`,
                                headers = {"Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders,
                                body = `body`)
    `ctx`.response = response

macro resp*(response: Response) =
  ## handy to make ctx's response
  var ctx = ident"ctx"

  result = quote do:
    `ctx`.response = `response`
