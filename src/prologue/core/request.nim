when defined(windows) or defined(usestd):
  import naive/request
else:
  import beast/request

export request
