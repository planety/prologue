import mimetypes
from nativeSockets import Port


type
  Settings* = ref object
    port*: Port
    debug*: bool
    reusePort*: bool
    mimeDB*: MimeDB
    staticDir*: string
    appName*: string


proc newSettings*(port = Port(8080), debug = false, reusePort = true,
    staticDir = "/static", appName = ""): Settings =
  Settings(port: port, debug: debug, reusePort: reusePort, staticDir: staticDir,
    mimeDB: newMimetypes(), appName: appName)
