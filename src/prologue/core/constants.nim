const
  PrologueVersion* = "0.6.4"            ## The current version of Prologue.
  ProloguePrefix* = "PROLOGUE"          ## The helper prefix for environment variables.
  useAsyncHTTPServer* = defined(windows) or defined(usestd) ## Uses `asynchttpserver`.
