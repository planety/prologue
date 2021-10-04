import std/[times, json, strformat, options, macros]

import ./httpcore/httplogue

import pkg/cookiejar


type
  Response* = object            ## Response object.
    httpVersion*: HttpVersion
    code*: HttpCode
    headers*: ResponseHeaders
    body*: string


func `$`*(response: Response): string =
  ## Gets the string form of `Response`.
  fmt"{response.code} {response.headers}"

func initResponse*(httpVersion: HttpVersion, code: HttpCode, headers =
                   {"Content-Type": "text/html; charset=UTF-8"}.initResponseHeaders,
                   body = ""): Response {.inline.} =
  ## Initializes a response.
  Response(httpVersion: httpVersion, code: code, headers: headers, body: body)

func initResponse*(httpVersion: HttpVersion, code: HttpCode, 
                   headers: openArray[(string, string)],
                   body = ""): Response {.inline.} =
  ## Initializes a response.
  Response(httpVersion: httpVersion, code: code,
           headers: headers.initResponseHeaders, body: body)

template hasHeader*(response: Response, key: string): bool =
  ## Returns true if key is in the `response`.
  response.headers.hasKey(key)

template getHeader*(response: Response, key: string): seq[string] =
  ## Retrieves value of `response.headers[key]`.
  response.headers[key]

template getHeaderOrDefault*(response: Response, key: string, default = @[""]): seq[string] =
  ## Retrieves value of `response.headers[key]`. Otherwise `default` will be returned.
  response.headers.getOrDefault(key, default)

template setHeader*(response: var Response, key, value: string) =
  ## Sets the header values of the response.
  response.headers[key] = value

template setHeader*(response: var Response, key: string, value: seq[string]) =
  ## Sets the header values of the response.
  response.headers[key] = value

template addHeader*(response: var Response, key, value: string) =
  ## Adds header values to the existing `HttpHeaders`.
  response.headers.add(key, value)

template setCookie*(response: var Response, cookie: Cookie) =
  ## Sets the cookie of response.
  response.addHeader("Set-Cookie", $cookie)

template setCookie*(response: var Response, key, value: string, expires = "",
                maxAge: Option[int] = none(int), domain = "", path = "", secure = false,
                httpOnly = false, sameSite = Lax) =
  ## Sets the cookie of response.
  let cookies = initCookie(key, value, expires, maxAge, domain, 
                           path, secure, httpOnly, sameSite)
  response.setCookie(cookies)

template setCookie*(response: var Response, key, value: string, expires: DateTime|Time, 
                maxAge: Option[int] = none(int), domain = "",
                path = "", secure = false, httpOnly = false, sameSite = Lax) =
  ## Sets the cookie of response.
  let cookies = initCookie(key, value, expires, maxAge, domain, 
                          path, secure, httpOnly, sameSite)
  response.setCookie(cookies)

template deleteCookie*(response: var Response, key: string, value = "", path = "",
                   domain = "") =
  ## Deletes the cookie of the response.
  response.setCookie(key, value, expires = secondsForward(0), maxAge = some(0),
                     path = path, domain = domain)

func abort*(code = Http401, body = "", headers = initResponseHeaders(),
            version = HttpVer11): Response {.inline.} =
  ## Returns the response with Http401 code(do not raise exception).
  result = initResponse(version, code = code, body = body,
                        headers = headers)

func redirect*(url: string, code = Http301,
               body = "", delay = 0, headers = initResponseHeaders(),
               version = HttpVer11): Response {.inline.} =
  ## Redirects to new url.
  result = initResponse(version, code = code, headers = headers, body = body)
  
  if delay == 0:
    result.headers.add("Location", url)
  else:
    result.headers.add("refresh", &"{delay};url=\"{url}\"")

func error404*(code = Http404,
               body = "<h1>404 Not Found!</h1>", headers = initResponseHeaders(),
               version = HttpVer11): Response {.inline.} =
  ## Creates an error 404 response.
  result = initResponse(version, code = code, body = body, headers = headers)

func htmlResponse*(text: string, code = Http200, headers = initResponseHeaders(),
                   version = HttpVer11): Response {.inline.} =
  ## Content-Type: text/html; charset=UTF-8.
  result = initResponse(version, code, headers, body = text)
  result.headers["Content-Type"] = "text/html; charset=UTF-8"

func plainTextResponse*(text: string, code = Http200,
                        headers = initResponseHeaders(), version = HttpVer11): Response {.inline.} =
  ## Content-Type: text/plain.
  result = initResponse(version, code, headers, body = text)
  result.headers["Content-Type"] = "text/plain"

func jsonResponse*(text: JsonNode, code = Http200, headers = initResponseHeaders(),
                   version = HttpVer11): Response {.inline.} =
  ## Content-Type: application/json.
  result = initResponse(version, code, headers, body = $text)
  result.headers["Content-Type"] = "application/json"

macro respDefault*(code: HttpCode) =
  ## Uses default error handler registered in the error handler table if existing.
  var ctx = ident"ctx"

  result = quote do:
    `ctx`.response.code = `code`
    `ctx`.response.body.setLen(0)

macro resp*(body: string, code = Http200, version = HttpVer11) =
  ## Handy to make a response of ctx.
  var ctx = ident"ctx"

  result = quote do:
    `ctx`.response.httpVersion = `version`
    `ctx`.response.code = `code`
    `ctx`.response.body = `body`


macro resp*(response: Response) =
  ## Handy to make a response of ctx.
  var ctx = ident"ctx"

  result = quote do:
    `ctx`.response = `response`
