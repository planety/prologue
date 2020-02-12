import httpclient, asyncdispatch, nativesockets
import strformat
import os, osproc


proc testRoute*(route, expected: string, address = "127.0.0.1", port = Port(8080)) {.async.} = 
  var client = newAsyncHttpClient()
  let value = await client.getContent(fmt"http://{address}:{port}{route}")
  echo value
  # doAssert(value == expected, fmt"Expect: {expected}, but got: {value}")


when defined(windows):
  if not existsFile("start_server.exe"):
    discard execProcess("nim c --hints:off start_server.nim")
else:
  if not existsFile("start_server"):
    discard execProcess("nim c --hints:off start_server.nim")

let process = startProcess("start_server")

# echo ^execC
waitFor testRoute(route = "/", "<h1>Home</h1>")
waitFor testRoute(route = "/hello", "<h1>Hello, Prologue!</h1>")
waitFor testRoute(route = "/home", "<h1>Home</h1>")
waitFor testRoute(route = "/home", "<h1>Home</h1>")
process.terminate()



echo "ok"
