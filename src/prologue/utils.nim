import uri, httpcore, httpclient, asyncdispatch, asyncnet


import os, tables, strutils, strformat



type
  PrologueError* = object of Exception
  RouteError* = object of PrologueError
  RouteResetError* = object of PrologueError
  Request* = object
    httpMethod*: HttpMethod
    httpUrl*: Uri
    httpVersion*: HttpVersion
    httpHeaders*: HttpHeaders # HttpHeaders = ref object
                              #   table*: TableRef[string, seq[string]]
    hostName*: string
    body*: string
    cookies*: Table[string, string]

  Response* = object
    client*: AsyncSocket
    httpVersion*: HttpVersion
    status*: HttpCode
    httpHeaders*: HttpHeaders
    body*: string

  AsyncHttpServer* = ref object
    hostName: string
    port: int
    reuseAddr, reusePort: bool
    maxBody: int

proc `$`(version: HttpVersion): string {.inline.} =
  case version
  of HttpVer10:
    result = "Http/1.0"
  of HttpVer11:
    result = "Http/1.1"

proc newAsyncHttpServer*(hostName: string = "127.0.0.1",
    port: int = 8080): AsyncHttpServer {.inline.} =
  AsyncHttpServer(hostName: hostName, port: port)

proc parseStartLine*(s: string, request: var Request) {.inline.} =
  let params = s.splitWhitespace
  # assert params.len == 3, $params
  if params.len != 3:
    return
  case params[0]
  of "Head":
    request.httpMethod = HttpHead
  of "Get":
    request.httpMethod = HttpGet
  of "Post":
    request.httpMethod = HttpPost
  else:
    discard
  request.httpUrl = parseUri(params[1])
  case params[2]
  of "HTTP/1.0":
    request.httpVersion = HttpVer10
  of "HTTP/1.1":
    request.httpVersion = HttpVer11
  else:
    discard

proc parseHttpRequest*(client: AsyncSocket, hostName: string): Future[
    Request] {.async.} =
  result.httpHeaders = newHttpHeaders()
  result.hostName = hostName
  echo result
  let startLine = await client.recvLine()
  if startLine == "":
    return
  echo startLine
  startLine.parseStartLine(result)
  while true:
    let line = await client.recvLine
    if line == "\c\L":
      break
    let pairs = line.parseHeader
    result.httpHeaders[pairs.key] = pairs.value
  echo result
  if result.httpHeaders.hasKey("Content-Length"):
    result.body = await client.recv(parseInt(result.httpHeaders[
        "Content-Length"]))
  echo result

proc `$`(rep: Response): string {.inline.} =
  result = &"{rep.httpVersion} {rep.status}\c\L"
  result.add "Server: Prologue\c\L"
  result.add "Content-type: text/html; charset=UTF-8\c\L"
  result.add &"Content-Length: {rep.body.len}"
  result.add "\c\L\c\L"
  result.add rep.body

proc handleHtml*(path: string, version: HttpVersion,
    status: HttpCode): Response =
  var
    f: File
    path = path
  if path.splitFile.ext == "":
    path &= ".html"
  if not existsFile(path):
    result.body = "<h1>404 Not Found!</h1>"
    result.httpVersion = HttpVer11
    result.status = Http404
    return
  try:
    f = open(path, fmRead)
  except IOError:
    return
  defer: f.close()
  result.body = f.readAll()
  result.httpVersion = version
  result.status = status

proc handle(url: Uri, version: HttpVersion, status: HttpCode): Response =
  let path = url.path
  if path.isRootDir:
    return handleHtml("index.html", version, status)
  let pathStrip = path.strip(chars = {'/'})
  return handleHtml(pathStrip, version, status)

proc handleRequest(req: Request): Response =
  echo req.httpMethod
  case req.httpMethod
  of HttpHead:
    result = handle(req.httpUrl, req.httpVersion, Http200)
  of HttpGet:
    result = handle(req.httpUrl, req.httpVersion, Http200)
  else:
    discard

proc sendResponse(client: AsyncSocket, response: Response): Future[void] =
  client.send($response)

proc start*(server: AsyncHttpServer) {.async.} =
  var socket = newAsyncSocket()
  socket.setSockOpt(OptReuseAddr, true)
  socket.bindAddr(Port(server.port), server.hostName)
  socket.listen()
  echo fmt"Prologue serve at {server.hostName}:{server.port}"

  while true:
    let (address, client) = await socket.acceptAddr()
    echo "Client connected from: ", address
    let
      req = await client.parseHttpRequest(address)
      response = req.handleRequest
    echo response
    await client.sendResponse(response)
    client.close()
    echo "over"

when isMainModule:
  var s = newAsyncHttpServer(port = 5000)
  waitFor s.start()
