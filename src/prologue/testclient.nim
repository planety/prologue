import httpclient, asyncdispatch, strformat


# proc test*(address = "127.0.0.1", port = Port(8080), route = "") {.async.} = 
#   var client = newAsyncHttpClient()
#   echo await client.getContent(fmt"{address}:{port.int}{route}")

when isMainModule:
  # waitFor test()
  # waitFor test(route = "/hello")
  # waitFor test(route = "/home")
  var client = newHttpClient()
  echo client.getContent("127.0.0.1:8080/hello")
