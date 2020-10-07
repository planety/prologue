import std/strtabs

import ./constants


when useAsyncHTTPServer:
  const additionalSettings* = {"maxBody": "stdlib_maxBody"}
else:
  const additionalSettings* = {"numThreads": "httpx_numThreads"}


func getServerSettingsName*(key: string): string {.inline.} =
  ## Retrieves the key in additional settings ignoring the style of the key.
  ## If key is not in the settings, it will raise `KeyError`.
  let settings = additionalSettings.newStringTable(modeStyleInsensitive)
  result = settings[key]

func getServerSettingsNameOrKey*(key: string): string {.inline.} =
  ## Retrieves the key in additional settings ignoring the style of the key.
  ## If key is not in the settings, the origin key will be returned.
  let settings = additionalSettings.newStringTable(modeStyleInsensitive)
  if settings.hasKey(key):
    result = settings[key]
  else:
    result = key
