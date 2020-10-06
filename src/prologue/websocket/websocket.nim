when (compiles do: import websocketx):
  import websocketx
  export websocketx
else:
  {.error: "Please use `logue extension websocket` to install!".}

