import uri, cgi, net, httpcore, httpclient, asyncdispatch, asyncnet


import os, tables, times, strutils, strformat


const
  Page = """<html>
<body>
<p>Hello, Nim!</p>
</body>
</html>
"""


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
    client*: Socket
    httpVersion*: HttpVersion
    status*: HttpCode
    httpHeaders*: HttpHeaders
    body*: string

  HttpServer* = ref object
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

proc initHttpServer*(hostName: string = "127.0.0.1",
    port: int = 8080): HttpServer {.inline.} =
  HttpServer(hostName: hostName, port: port)

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

proc parseHttpRequest*(client: Socket, hostName: string): Request =
  result.httpHeaders = newHttpHeaders()
  result.hostName = hostName
  let startLine = client.recvLine
  startLine.parseStartLine(result)
  while true:
    let line = client.recvLine
    if line == "\c\L":
      break
    let pairs = line.parseHeader
    result.httpHeaders[pairs.key] = pairs.value

# proc handleRequest(version: HttpVersion, status: HttpCode, data: string): string =
#   result = $version & $status & "\c\L"
#   result.add "Server: Prologue" & "\c\L"
#   result.add "Content-type: text/html; charset=UTF-8\c\L"
#   result.add &"Content-Length: {data.len}"
#   result.add "\c\L\c\L"
#   result.add data

proc `$`(rep: Response): string {.inline.} =
  result = &"{rep.httpVersion} {rep.status}\c\L"
  result.add "Server: Prologue\c\L"
  result.add "Content-type: text/html; charset=UTF-8\c\L"
  result.add &"Content-Length: {rep.body.len}"
  result.add "\c\L\c\L"
  result.add rep.body
   

proc handleHtml*(path: string, version: HttpVersion, status: HttpCode): Response =
  var f: File
  try:
    f = open(path, fmRead)
  except IOError:
    return
  defer: f.close()
  result.body = f.readAll()
  result.httpVersion = version
  result.status = status

proc handleHead(url: Uri, version: HttpVersion, status: HttpCode): Response =
  let path = url.path
  if path.isRootDir:
    return handleHtml("index.html", version, status)
  let pathStrip = path.strip(chars={'/'})
  return handleHtml(pathStrip, version, status)
  # echo pathStrip
  # let pathSplit = splitPath(path)
  # echo pathSplit.repr


proc handleRequest(req: Request): Response =
  case req.httpMethod
  of HttpHead:
    result = handleHead(req.httpUrl, req.httpVersion, Http200)
  of HttpGet:
    discard
  else:
    discard

proc start*(server: HttpServer) =
  var socket = newSocket()
  socket.bindAddr(Port(server.port), server.hostName)
  socket.listen()
  echo fmt"Prologue serve at {server.hostName}:{server.port}"

  var
    client: Socket
    address = ""
  while true:
    socket.acceptAddr(client, address)
    echo "Client connected from: ", address
    let
      req = client.parseHttpRequest(address)
      response = req.handleRequest
      # response = handleRequest(HttpVer11, HttpCode(200), Page)
    echo response
    client.send($response)
    client.close()


proc body*(req: Request) {.async.} =
  while true:
    break

when isMainModule:
  var s = initHttpServer(port = 5000)
  s.start()
