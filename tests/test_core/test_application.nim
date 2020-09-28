discard """
  cmd:      "nim c -r --styleCheck:hint --panics:on $options $file"
  matrix:   "--gc:refc"
  targets:  "c"
  nimout:   ""
  action:   "run"
  exitcode: 0
  timeout:  60.0
"""
import httpclient, asyncdispatch, nativesockets
import strformat, os, osproc, terminal, strutils


import ./utils


var process: Process
when defined(windows):
  if not fileExists("tests/start_server.exe"):
    let code = execCmd("nim c --hints:off --verbosity=0 tests/start_server.nim")
    if code != 0:
      raise newException(IOError, "can't compile tests/start_server.nim")
  process = startProcess(expandFileName("tests/start_server.exe"))
elif not defined(windows) and defined(usestd):
  if not fileExists("tests/start_server"):
    let code = execCmd("nim c --hints:off -d:usestd tests/start_server.nim")
    if code != 0:
      raise newException(IOError, "can't compile tests/start_server.nim")
  process = startProcess(expandFileName("tests/start_server"))
else:
  if not fileExists("tests/start_server"):
    let code = execCmd("nim c --hints:off tests/start_server.nim")
    if code != 0:
      raise newException(IOError, "can't compile tests/start_server.nim")
  process = startProcess(expandFileName("tests/start_server"))

proc start() {.async.} =
  let address = "http://127.0.0.1:8080/home"
  for i in 0 .. 20:
    var client = newAsyncHttpClient()
    styledEcho(fgBlue, "Getting ", address)
    let fut = client.get(address)
    yield fut or sleepAsync(4000)
    if not fut.finished:
      styledEcho(fgYellow, "Timed out")
    elif not fut.failed:
      styledEcho(fgGreen, "Server started!")
      return
    else: echo fut.error.msg
    client.close()


waitFor start()


# proc houndredsRequest(client: AsyncHttpClient, address: string, port: Port, route: string,num: int = 100000) {.async.} =
#   for i in 0 ..< num:
#     echo await client.getContent(fmt"http://{address}:{port}{route}")
#     echo i

# "Test Application"
block:
  let
    client = newAsyncHttpClient()
    address = "127.0.0.1"
    port = Port(8080)

  # test "can handle houndreds of reuqest":
  #   let
  #     route = "/"
  #   echo "begin"
  #   waitFor client.houndredsRequest(address, port, route)
  #   echo "end"

  # "can get /"
  block:
    let
      route = "/"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")

    doAssert response.code == Http200, $response.code
    doAssert (waitFor response.body) == "<h1>Home</h1>"

  # "can get /hello"
  block:
    let
      route = "/hello"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")

    doAssert response.code == Http200, $response.code
    doAssert (waitFor response.body) == "<h1>Hello, Prologue!</h1>"

  # "can get /home"
  block:
    let
      route = "/home"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")

    doAssert response.code == Http200, $response.code
    doAssert (waitFor response.body) == "<h1>Home</h1>"

  # "can get /home?json"
  block:
    let
      route = "/home?json"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")

    doAssert response.code == Http200, $response.code
    doAssert (waitFor response.body) == "<h1>Home</h1>"

  # "can get /hello/{name} with name = Starlight"
  block:
    let
      route = "/hello/Starlight"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")

    doAssert response.code == Http200, $response.code
    doAssert (waitFor response.body) == "<h1>Hello, Starlight</h1>"

  # "can get /hello/{name} with name = "
  block:
    let
      route = "/hello/"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")
    
    doAssert response.code == Http200, $response.code
    doAssert (waitFor response.body) == "<h1>Hello, Prologue!</h1>"

  # "can redirect /home"
  block:
    let
      route = "/redirect"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")

    doAssert response.code == Http200, $response.code
    doAssert (waitFor response.body) == "<h1>Home</h1>"

  # "can get /loginget using get method"
  block:
    let
      route = "/loginget"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")

    doAssert response.code == Http200, $response.code
    doAssert (waitFor response.body) == loginGetPage()

  when defined(usestd):
    # "can post /loginpage"
    block:
      let
        route = "/loginpage"
      var data = newMultipartData()
      data["username"] = "starlight"
      data["password"] = "prologue"
      doAssert (waitFor client.postContent(fmt"http://{address}:{port}{route}",
                multipart = data)) == "<h1>Hello, Nim</h1>"

  # "can get /login using post method"
  block:
    let
      route = "/login"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")

    doAssert response.code == Http200, $response.code
    doAssert (waitFor response.body) == loginPage()

  when defined(usestd):
    # "can post /login"
    block:
      let
        route = "/login"
      var data = newMultipartData()
      data["username"] = "starlight"
      data["password"] = "prologue"
      doAssert (waitFor client.postContent(fmt"http://{address}:{port}{route}",
          multipart = data)) == "<h1>Hello, Nim</h1>"

  # "can get /translate"
  block:
    let
      route = "/translate"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")

    doAssert response.code == Http200, $response.code
    doAssert (waitFor response.body) == "I'm ok."

  # "can get /upload"
  block:
    let
      route = "/upload"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")

    doAssert response.code == Http200, $response.code
    doAssert (waitFor response.body) == readFile("tests/static/upload.html")

  # "can post /upload"
  block:
    let
      route = "/upload"
      filename = "test.txt"
      text = readFile("tests/static" / filename)
    var data = newMultipartData()
    data["file"] = (filename, "text/plain", text)
    let response = (waitFor client.post(fmt"http://{address}:{port}{route}",
        multipart = data))

    doAssert response.code == Http200, $response.code
    doAssert (waitFor response.body) == fmt"<html><h1>{filename}</h1><p>{text.strip()}</p></html>"

  block static_file_cache:
    let
      route = "/upload"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")
    client.headers = newHttpHeaders({ "If-None-Match": response.headers["etag", 0] })

    let
      cacheResponse = waitFor client.get(fmt"http://{address}:{port}{route}")

    doAssert cacheResponse.code == Http304

  block cookie_works_fine:
    let
      route = "/cookie"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")

    doAssert response.code == Http200, $response.code
    doAssert (waitFor response.body) == "Hello"

  client.close()
  process.terminate()
