import httpclient, asyncdispatch, strformat
import nativesockets


proc test*(route, expected: string, address = "127.0.0.1", port = Port(8080)) {.async.} = 
  var client = newAsyncHttpClient()
  let value = await client.getContent(fmt"http://{address}:{port}{route}")
  doAssert(value == expected, fmt"Expect: {expected}, but got: {value}")

when isMainModule:
  waitFor test(route = "/", "<h1>Home</h1>")
  waitFor test(route = "/hello", "<h1>Hello, Prologue!</h1>")
  waitFor test(route = "/home", "<h1>Home</h1>")
