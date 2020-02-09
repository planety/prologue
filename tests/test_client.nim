import httpclient, asyncdispatch, nativesockets
import strformat


proc testRoute*(route, expected: string, address = "127.0.0.1", port = Port(8080)) {.async.} = 
  var client = newAsyncHttpClient()
  let value = await client.getContent(fmt"http://{address}:{port}{route}")
  doAssert(value == expected, fmt"Expect: {expected}, but got: {value}")

when isMainModule:
  waitFor testRoute(route = "/", "<h1>Home</h1>")
  waitFor testRoute(route = "/hello", "<h1>Hello, Prologue!</h1>")
  waitFor testRoute(route = "/home", "<h1>Home</h1>")
