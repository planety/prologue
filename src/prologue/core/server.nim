import ./constants
from std/nativesockets import Port


when useAsyncHTTPServer:
  import ./naive/server
else:
  import ./beast/server

export server

func appAddress*(app: Prologue): string {.inline.} =
  ## Gets the address from the settings.
  app.gScope.settings.address

func appDebug*(app: Prologue): bool {.inline.} =
  ## Gets the debug attributes from the settings.
  app.gScope.settings.debug

func appName*(app: Prologue): string {.inline.} =
  ## Gets the appName attributes from the settings.
  app.gScope.settings.appName

func appPort*(app: Prologue): Port {.inline.} =
  ## Gets the port from the settings.
  app.gScope.settings.port
