import httpclient, asyncdispatch, nativesockets
import strformat, os, osproc

import unittest


when defined(windows):
  if not existsFile("start_server.exe"):
    discard execProcess("nim c --hints:off start_server.nim")
else:
  if not existsFile("start_server"):
    discard execProcess("nim c --hints:off start_server.nim")


suite "Test Application":
  let 
    process = startProcess("start_server")
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
