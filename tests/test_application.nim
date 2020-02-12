import httpclient, asyncdispatch, nativesockets
import strformat, os, osproc

import unittest


when defined(windows):
  if not existsFile("start_server.exe"):
    let code = execCmd("nim c --hints:off tests/start_server.nim")
    if code != 0:
      raise newException(IOError, "can't compile tests/start_server.nim")
  let process = startProcess("start_server")
else:
  if not existsFile("start_server"):
    let code = execCmd("nim c --hints:off tests/start_server.nim")
    if code != 0:
      raise newException(IOError, "can't compile tests/start_server.nim")
  let process = startProcess("./start_server")


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

  process.terminate()
