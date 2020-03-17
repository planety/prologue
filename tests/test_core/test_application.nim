import httpclient, asyncdispatch, nativesockets
import strformat, os, osproc, terminal


import unittest

import ./utils


var process: Process
when defined(windows):
  if not existsFile("start_server.exe"):
    let code = execCmd("nim c --hints:off --verbosity=0 tests/start_server.nim")
    if code != 0:
      raise newException(IOError, "can't compile tests/start_server.nim")
    process = startProcess(expandFileName("tests/start_server.exe"))
elif not defined(windows) and defined(usestd):
  if not existsFile("start_server"):
    let code = execCmd("nim c --hints:off -d:usestd tests/start_server.nim")
    if code != 0:
      raise newException(IOError, "can't compile tests/start_server.nim")
    process = startProcess(expandFileName("tests/start_server"))
else:
  if not existsFile("start_server"):
    let code = execCmd("nim c --hints:off tests/start_server.nim")
    if code != 0:
      raise newException(IOError, "can't compile tests/start_server.nim")
    process = startProcess(expandFileName("tests/start_server"))

proc start() {.async.} =
  let address = "http://127.0.0.1:8080/home"
  for i in 0 .. 10:
    var client = newAsyncHttpClient()
    styledEcho(fgBlue, "Getting ", address)
    let fut = client.get(address)
    yield fut or sleepAsync(3000)
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

suite "Test Application":
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

  test "can get /":
    let
      route = "/"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")
    check:
      response.code == Http200
      (waitFor response.body) == "<h1>Home</h1>"

  test "can get /hello":
    let
      route = "/hello"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")
    check:
      response.code == Http200
      (waitFor response.body) == "<h1>Hello, Prologue!</h1>"

  test "can get /home":
    let
      route = "/home"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")
    check:
      response.code == Http200
      (waitFor response.body) == "<h1>Home</h1>"

  test "can get /hello/{name} with name = Starlight":
    let
      route = "/hello/Starlight!"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")
    check:
      response.code == Http200
      (waitFor response.body) == "<h1>Hello, Starlight!</h1>"

  test "can get /hello/{name} with name = ":
    let
      route = "/hello/"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")
    check:
      response.code == Http200
      (waitFor response.body) == "<h1>Hello, Prologue!</h1>"

  test "can redirect /home":
    let
      route = "/redirect"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")
    check:
      response.code == Http200
      (waitFor response.body) == "<h1>Home</h1>"

  test "can get /loginget using get method":
    let
      route = "/loginget"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")
    check:
      response.code == Http200
      (waitFor response.body) == loginGetPage()

  when defined(windows) or defined(usestd):
    test "can get /loginpage":
      let
        route = "/loginpage"
      var data = newMultipartData()
      data["username"] = "starlight"
      data["password"] = "prologue"
      check (waitFor client.postContent(fmt"http://{address}:{port}{route}",
          multipart = data)) == "<h1>Hello, Nim</h1>"

  test "can get /login using post method":
    let
      route = "/login"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")
    check:
      response.code == Http200
      (waitFor response.body) == loginPage()

  when defined(windows) or defined(usestd):
    test "can post /login":
      let
        route = "/login"
      var data = newMultipartData()
      data["username"] = "starlight"
      data["password"] = "prologue"
      check (waitFor client.postContent(fmt"http://{address}:{port}{route}",
          multipart = data)) == "<h1>Hello, Nim</h1>"

  test "can get /translate":
    let
      route = "/translate"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")
    check:
      response.code == Http200
      (waitFor response.body) == "I'm ok."

  client.close()
  process.terminate()
