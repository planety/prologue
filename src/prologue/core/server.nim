when defined(windows) or defined(usestd):
  import naive/server
else:
  import beast/server

export server
