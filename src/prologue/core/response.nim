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
  ## Stringify response.
  fmt"{response.code} {response.headers}"

proc initResponse*(httpVersion: HttpVersion, code: HttpCode, headers =
                   {"Content-Type": "text/html; charset=UTF-8"}.newHttpHeaders,
                   body = ""): Response {.inline.} =
  ## Initializes response.
  Response(httpVersion: httpVersion, code: code, headers: headers, body: body)

template hasHeader*(response: Response, key: string): bool =
  ## Returns true if key is in the `response`.
  response.headers.hasKey(key)

template setHeader*(response: var Response, key, value: string) =
  ## Sets the header values of the response.
  response.headers[key] = value

template setHeader*(response: var Response, key: string, value: seq[string]) =
  ## Sets the header values of the response.
  response.headers[key] = value

template addHeader*(response: var Response, key, value: string) =
  ## Adds header values to the existing `HttpHeaders`.
  response.headers.add(key, value)

template setCookie*(response: var Response, key, value: string, expires = "",
                maxAge: Option[int] = none(int), domain = "", path = "", secure = false,
                httpOnly = false, sameSite = Lax) =
  ## Sets the cookie of response.
  let cookies = initCookie(key, value, expires, maxAge, domain, 
                           path, secure, httpOnly, sameSite)
  if unlikely(response.headers == nil):
    response.headers = newHttpHeaders()
  response.addHeader("Set-Cookie", $cookies)

template setCookie*(response: var Response, key, value: string, expires: DateTime|Time, 
                maxAge: Option[int] = none(int), domain = "",
                path = "", secure = false, httpOnly = false, sameSite = Lax) =
  ## Sets the cookie of response.
  let cookies = initCookie(key, value, expires, maxAge, domain, 
                          path, secure, httpOnly, sameSite)
  if unlikely(response.headers == nil):
    response.headers = newHttpHeaders()
  response.addHeader("Set-Cookie", $cookies)

template deleteCookie*(response: var Response, key: string, value = "", path = "",
                   domain = "") =
  response.setCookie(key, value, expires = secondsForward(0), maxAge = some(0),
                     path = path, domain = domain)

func abort*(code = Http401, body = "", headers = newHttpHeaders(),
            version = HttpVer11): Response {.inline.} =
  result = initResponse(version, code = code, body = body,
                        headers = headers)

func redirect*(url: string, code = Http301,
               body = "", delay = 0, headers = newHttpHeaders(),
               version = HttpVer11): Response {.inline.} =
  ## redirect to new url.
  result = initResponse(version, code = code, headers = headers, body = body)
  if unlikely(result.headers == nil):
    result.headers = newHttpHeaders()
  
  if delay == 0:
    result.headers.add("Location", url)
  else:
    result.headers.add("refresh", &"{delay};url=\"{url}\"")

func error404*(code = Http404,
               body = "<h1>404 Not Found!</h1>", headers = newHttpHeaders(),
               version = HttpVer11): Response {.inline.} =
  ## 404 HTML.
  result = initResponse(version, code = code, body = body, headers = headers)

func htmlResponse*(text: string, code = Http200, headers = newHttpHeaders(),
                   version = HttpVer11): Response {.inline.} =
  ## Content-Type: text/html; charset=UTF-8.
  result = initResponse(version, code, headers, body = text)
  if unlikely(result.headers == nil):
    result.headers = newHttpHeaders()
  result.headers["Content-Type"] = "text/html; charset=UTF-8"

func plainTextResponse*(text: string, code = Http200,
                        headers = newHttpHeaders(), version = HttpVer11): Response {.inline.} =
  ## Content-Type: text/plain.
  result = initResponse(version, code, headers, body = text)
  if unlikely(result.headers == nil):
    result.headers = newHttpHeaders()
  result.headers["Content-Type"] = "text/plain"

func jsonResponse*(text: JsonNode, code = Http200, headers = newHttpHeaders(),
                   version = HttpVer11): Response {.inline.} =
  ## Content-Type: application/json.
  result = initResponse(version, code, headers, body = $text)
  if unlikely(result.headers == nil):
    result.headers = newHttpHeaders()
  result.headers["Content-Type"] = "text/json"

macro resp*(body: string, code = Http200) =
  ## Handy to make a response of ctx.
  var ctx = ident"ctx"

  result = quote do:
    `ctx`.response.httpVersion = HttpVer11
    `ctx`.response.code = `code`
    `ctx`.response.body = `body`


macro resp*(response: Response) =
  ## Handy to make a response of ctx.
  var ctx = ident"ctx"

  result = quote do:
    `ctx`.response = `response`
