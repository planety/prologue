import net, httpcore, httpclient, asyncdispatch, asyncnet


import uri, cgi, tables


const
  Page = """
<html>
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
    path: string
    body*: string
    cookies*: Table[string, string]

  Response* = object
    httpVersion*: HttpVersion
    status*: HttpCode
    httpHeaders*: HttpHeaders
    body*: string

  HttpServer* = object
    hostName: string
    port: int


proc initHttpServer*(hostName: string = "127.0.0.1", port: int = 8080): HttpServer = 
  HttpServer(hostName: hostName, port: port)

proc start*(server: HttpServer) = 
  var socket = newSocket()
  socket.bindAddr(Port(server.port))
  socket.listen()

  var 
    client: Socket
    address = ""
  while true:
    socket.acceptAddr(client, address)
    echo "Client connected from: ", address
    let data = client.recv(1024)
    echo data
    client.send(data)
    client.send("hello")
    client.close()


proc body*(req: Request) {.async.} =
  while true:
    break

when isMainModule:
  var s = initHttpServer()
  s.start()
