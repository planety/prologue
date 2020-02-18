import mimetypes
from nativeSockets import Port

from types import SecretKey


type
  Settings* = ref object
    port*: Port
    debug*: bool
    reusePort*: bool
    mimeDB*: MimeDB
    staticDirs*: seq[string]
    secretKey*: SecretKey
    appName*: string


proc newSettings*(port = Port(8080), debug = true, reusePort = true,
    staticDirs = @["/static"], secretKey = SecretKey(""), appName = ""): Settings =
  Settings(port: port, debug: debug, reusePort: reusePort, staticDirs: staticDirs,
    mimeDB: newMimetypes(), secretKey: secretKey, appName: appName)
