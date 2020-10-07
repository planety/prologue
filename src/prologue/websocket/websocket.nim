when (compiles do: import websocketx):
  import pkg/websocketx
  export websocketx
else:
  {.error: "Please use `logue extension websocket` to install!".}

