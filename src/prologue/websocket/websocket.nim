when (compiles do: import websocketx):
  import pkg/websocketx
  export websocketx
else:
  {.error: "Please use `logue extension websocketx` to install!".}

import ../core/context

import std/asyncdispatch


proc newWebSocket*(ctx: Context): Future[WebSocket] =
  result = newWebSocket(ctx.request.nativeRequest)
