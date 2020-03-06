import mimetypes 
from nativeSockets import Port

from types import SecretKey, EmptySecretKeyError, len
from urandom import randomSecretKey


type
  Settings* = ref object
    port*: Port
    debug*: bool
    reusePort*: bool
    mimeDB*: MimeDB
    staticDirs*: seq[string]
    secretKey*: SecretKey
    appName*: string
    dbPath*: string


proc newSettings*(port = Port(8080), debug = true, reusePort = true,
    staticDirs = "static", secretKey = randomSecretKey(8), appName = "", dbPath = ""): Settings =
  if secretKey.len == 0:
    raise newException(EmptySecretKeyError, "Secret key can't be empty!")
  Settings(port: port, debug: debug, reusePort: reusePort, staticDirs: @[staticDirs],
    mimeDB: newMimetypes(), secretKey: secretKey, appName: appName, dbPath: dbPath)
