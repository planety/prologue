import ./constants


when useAsyncHTTPServer:
  import ./naive/server
else:
  import ./beast/server

export server
