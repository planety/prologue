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

echo Page.len

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



proc body*(req: Request) {.async.} =
  while true:
    break
