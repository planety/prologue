discard """
  cmd:      "nim c -r --styleCheck:hint --panics:on $options $file"
  matrix:   "--gc:refc; --gc:refc -d:usestd"
  targets:  "c"
  nimout:   ""
  action:   "run"
  exitcode: 0
  timeout:  60.0
"""
import ../../../src/prologue/core/defaultserversettings
import ../../../src/prologue/core/constants
import std/strtabs


block:
  let settings = additionalSettings.newStringTable(modeStyleInsensitive)
  when useAsyncHTTPServer:
    doAssert settings.hasKey("maxBody")
  else:
    doAssert settings.hasKey("numThreads")

block:
  when useAsyncHTTPServer:
    doAssert getServerSettingsName("max_body") == "stdlib_maxBody"
    doAssert getServerSettingsName("maxbody") == "stdlib_maxBody"
    doAssert getServerSettingsName("maxBody") == "stdlib_maxBody"

    doAssert getServerSettingsNameOrKey("max_body") == "stdlib_maxBody"
    doAssert getServerSettingsNameOrKey("maxbody") == "stdlib_maxBody"
    doAssert getServerSettingsNameOrKey("maxBody") == "stdlib_maxBody"

    doAssert getServerSettingsNameOrKey("numThreads") == "numThreads"
    doAssert getServerSettingsNameOrKey("num_threads") == "num_threads"
    doAssert getServerSettingsNameOrKey("numthreads") == "numthreads"

    doAssertRaises(KeyError):
      discard getServerSettingsName("numThreads")

  else:
    doAssert getServerSettingsNameOrKey("max_body") == "max_body"
    doAssert getServerSettingsNameOrKey("maxbody") == "maxbody"
    doAssert getServerSettingsNameOrKey("maxBody") == "maxBody"

    doAssert getServerSettingsName("numThreads") == "httpx_numThreads"
    doAssert getServerSettingsName("num_threads") == "httpx_numThreads"
    doAssert getServerSettingsName("numthreads") == "httpx_numThreads"

    doAssert getServerSettingsNameOrKey("numThreads") == "httpx_numThreads"
    doAssert getServerSettingsNameOrKey("num_threads") == "httpx_numThreads"
    doAssert getServerSettingsNameOrKey("numthreads") == "httpx_numThreads"

    doAssertRaises(KeyError):
      discard getServerSettingsName("maxBody")
  

