import ./constants
import std/strtabs


when useAsyncHTTPServer:
  const additionalSettings* = {"maxBody": "stdlib_maxBody"}
else:
  const additionalSettings* = {"numThreads": "httpx_numThreads"}


func getServerSettingsName*(key: string): string {.inline.} =
  let settings = additionalSettings.newStringTable(modeStyleInsensitive)
  result = settings[key]

func getServerSettingsNameOrKey*(key: string): string {.inline.} =
  let settings = additionalSettings.newStringTable(modeStyleInsensitive)
  if settings.hasKey(key):
    result = settings[key]
  else:
    result = key
