discard """
  cmd:      "nim c -r --styleCheck:hint --panics:on $options $file"
  matrix:   "--gc:refc"
  targets:  "c"
  action:   "run"
  exitcode: 0
  timeout:  60.0
"""
import std/[httpclient, asyncdispatch, nativesockets, strformat, os, osproc, terminal, strutils]


import ./utils

when defined(usestd):
  const toExecute = "nim c -d:usestd --hints:off --verbosity=0 tests/start_server.nim"
else:
  const toExecute = "nim c --hints:off --verbosity=0 tests/start_server.nim"

var process: Process

when defined(windows):
  if not fileExists("tests/start_server.exe"):
    let code = execCmd(toExecute)
    if code != 0:
      raise newException(IOError, "can't compile tests/start_server.nim")
  process = startProcess(expandFilename("tests/start_server.exe"))
else:
  if not fileExists("tests/start_server"):
    let code = execCmd(toExecute)
    if code != 0:
      raise newException(IOError, "can't compile tests/start_server.nim")
  process = startProcess(expandFilename("tests/start_server"))

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


# "Test Application"
block:
  let
    client = newAsyncHttpClient()
    address = "127.0.0.1"
    port = Port(8080)

  # test "can handle hundreds of request":
  #   let
  #     route = "/"
  #   echo "begin"
  #   waitFor client.hundredsRequest(address, port, route)
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

  # "can get /hello/{name} with name = Prologue"
  block:
    let
      route = "/hello/Prologue"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")

    doAssert response.code == Http200, $response.code
    doAssert (waitFor response.body) == "<h1>Hello, Prologue</h1>"

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
    doAssert (waitFor response.body) == readFile("tests/assets/static/upload.html")

  # "can post /upload"
  block:
    let
      route = "/upload"
      filename = "test.txt"
      text = readFile("tests/assets/static" / filename)
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

  block favicon:
    let
      route1 = "/favicon.ico"
      response1 = waitFor client.get(fmt"http://{address}:{port}{route1}")
      bodyLen1 = len(waitFor response1.body)

    doAssert response1.code == Http200

    let
      route2 = "/favicon"
      response2 = waitFor client.get(fmt"http://{address}:{port}{route2}")
      bodyLen2 = len(waitFor response2.body)

    doAssert response2.code == Http200

    doAssert bodyLen1 == bodyLen2

  # "can get static files via virtual path"
  block:
    # "can get static file via virtual path"
    block:
      let
        route = "/assets/favicons/favicon.ico"
        response = waitFor client.get(fmt"http://{address}:{port}{route}")

      doAssert response.code == Http200
    # "can get static file in nested dirs"
    block:
      let
        route = "/assets/favicons/A/B/C/important_text.txt"
        response = waitFor client.get(fmt"http://{address}:{port}{route}")

      doAssert response.code == Http200
    # "can get the same static file via different virtual path"
    block:
      let
        route = "/very/important/texts/important_text.txt"
        response = waitFor client.get(fmt"http://{address}:{port}{route}")

      doAssert response.code == Http200
    # "can get the same static file via different virtual path and nested dirs"
    block:
      let
        route = "/important/texts/A/B/C/important_text.txt"
        response = waitFor client.get(fmt"http://{address}:{port}{route}")

      doAssert response.code == Http200
    # "can get the same static file via different virtual path and overloaded dir"
    block:
      let
        route = "/important/texts/A/important_text.txt"
        response = waitFor client.get(fmt"http://{address}:{port}{route}")

      doAssert response.code == Http200
    

  client.close()
  process.terminate()
