when not (compiles do: import websocketx):
  {.error: "Please use `logue extension websocket` to install!".}
else:
  import websocketx
  export websocketx
