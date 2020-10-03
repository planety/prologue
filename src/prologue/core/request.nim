import constants


when useAsyncHTTPServer:
  import naive/request
else:
  import beast/request

export request
