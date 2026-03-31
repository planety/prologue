import ../core/context
import ../core/asyncbackend

when useKairos:
  import pkg/kairos/ws
  export ws

  proc newWebSocket*(ctx: Context): Future[WSSession] =
    ## Creates a new WebSocket session (chronos/websock).
    result = ctx.request.nativeRequest.upgradeToWebSocket()
else:
  when (compiles do: import websocketx):
    import pkg/websocketx
    export websocketx
  else:
    {.error: "Please use `logue extension websocketx` to install!".}

  proc newWebSocket*(ctx: Context): Future[WebSocket] =
    ## Creates a new WebSocket (asyncdispatch/ws).
    result = newWebSocket(ctx.request.nativeRequest)
