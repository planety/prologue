import mimetypes
from nativeSockets import Port

import types


type
  Settings* = ref object
    port*: Port
    debug*: bool
    reusePort*: bool
    mimeDB*: MimeDB
    staticDir*: string
    secretKey*: SecretKey
    appName*: string


proc newSettings*(port = Port(8080), debug = true, reusePort = true,
    staticDir = "/static", secretKey = SecretKey(""), appName = ""): Settings =
  Settings(port: port, debug: debug, reusePort: reusePort, staticDir: staticDir,
    mimeDB: newMimetypes(), secretKey: secretKey, appName: appName)
