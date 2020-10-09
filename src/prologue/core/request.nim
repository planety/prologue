import std/httpcore
import ./constants


when useAsyncHTTPServer:
  import ./naive/request
else:
  import ./beast/request

export request


func hasHeader*(request: Request, key: string): bool {.inline.} =
  ## Returns true if key is in `request.headers`.
  request.headers.hasKey(key)

func getHeader*(request: Request, key: string): seq[string] {.inline.} =
  ## Retrieves value of `request.headers[key]`.
  seq[string](request.headers[key])

func getHeaderOrDefault*(request: Request, key: string, default = @[""]): seq[string] {.inline.} =
  ## Retrieves value of `request.headers[key]`. Otherwise `default` will be returned.
  if request.headers.hasKey(key):
    result = getHeader(request, key)
  else:
    result = default

func setHeader*(request: var Request, key, value: string) {.inline.} =
  ## Inserts a (key, value) pair into `request.headers`.
  request.headers[key] = value

func setHeader*(request: var Request, key: string, value: seq[string]) {.inline.} =
  ## Inserts a (key, value) pair into `request.headers`.
  request.headers[key] = value

func addHeader*(request: var Request, key, value: string) {.inline.} =
  ## Appends value to the existing key in `request.headers`.
  request.headers.add(key, value)
