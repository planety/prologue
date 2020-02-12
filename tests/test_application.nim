import httpclient, asyncdispatch, nativesockets
import strformat, os, osproc, terminal

import unittest

import utils


when defined(windows):
  if not existsFile("start_server.exe"):
    let code = execCmd("nim c --hints:off tests/start_server.nim")
    if code != 0:
      raise newException(IOError, "can't compile tests/start_server.nim")
else:
  if not existsFile("start_server"):
    let code = execCmd("nim c --hints:off tests/start_server.nim")
    if code != 0:
      raise newException(IOError, "can't compile tests/start_server.nim")

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

let process = startProcess("tests/start_server")
waitFor start()


suite "Test Application":
  let
    client = newAsyncHttpClient()
    address = "127.0.0.1"
    port = Port(8080)

  test "can get /":
    let
      route = "/"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")
    check response.code == Http200
    check (waitFor response.body) == "<h1>Home</h1>"

  test "can get /hello":
    let
      route = "/hello"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")
    check response.code == Http200
    check (waitFor response.body) == "<h1>Hello, Prologue!</h1>"

  test "can get /home":
    let
      route = "/home"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")
    check response.code == Http200
    check (waitFor response.body) == "<h1>Home</h1>"

  test "can get /hello/{name} with name = Starlight":
    let
      route = "/hello/Starlight!"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")
    check response.code == Http200
    check (waitFor response.body) == "<h1>Hello, Starlight!</h1>"

  test "can get /hello/{name} with name = ":
    let
      route = "/hello/"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")
    check response.code == Http200
    check (waitFor response.body) == "<h1>Hello, Prologue!</h1>"

  test "can redirect /home":
    let
      route = "/redirect"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")
    check response.code == Http200
    check (waitFor response.body) == "<h1>Home</h1>"

  test "can get /login":
    let
      route = "/login"
      response = waitFor client.get(fmt"http://{address}:{port}{route}")
    check response.code == Http200
    check (waitFor response.body) == loginPage()

  test "can post /login":
    let
      route = "/login"
    var data = newMultipartData()
    data["username"] = "starlight"
    data["password"] = "prologue"
    check (waitFor client.postContent(fmt"http://{address}:{port}{route}",
        multipart = data)) == "<h1>Hello, Nim</h1>"

  client.close()
  process.terminate()
