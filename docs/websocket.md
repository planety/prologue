# Websocket

`Prologue` provides `websocket` supports, you need to install `websocketx` first(`nimble install websocketx` or `logue extension websocketx`).

## Echo server example

First create a new websocket object, then you can send msgs to the client. Finally, you receive msgs from the client and send them back to the client.

```nim
import prologue
import prologue/websocket


proc hello*(ctx: Context) {.async.} =
  var ws = await newWebSocket(ctx)
  await ws.send("Welcome to simple echo server")
  while ws.readyState == Open:
    let packet = await ws.receiveStrPacket()
    await ws.send(packet)

  resp "<h1>Hello, Prologue!</h1>"
```

## More details

You can ref to [ws](https://github.com/treeform/ws) to find more usages.
