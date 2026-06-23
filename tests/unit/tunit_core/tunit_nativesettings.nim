include ../../../src/prologue/core/nativesettings


block: # newSettings defaults
  let settings = newSettings()
  doAssert settings.address == ""
  doAssert settings.port.int == 8080
  doAssert settings.debug == true
  doAssert settings.reusePort == true

  doAssert settings.bufSize == 40960
  doAssert settings["prologue"].hasKey("secretKey")
  doAssert settings["prologue"]["secretKey"].getStr.len == 8
  doAssert settings["prologue"].getOrDefault("secretKey").getStr == settings["prologue"]["secretKey"].getStr
  doAssert settings.getOrDefault("empty").getStr.len == 0

block: # newSettings preserves user prologue data (#303)
  block: # data with existing prologue key
    let data = %* {"prologue": {"maxBody": 1_000}, "name": "test"}
    let settings = newSettings(data = data, secretKey = "mykey")
    doAssert settings["prologue"]["maxBody"].getInt == 1_000
    doAssert settings["prologue"]["secretKey"].getStr == "mykey"
    doAssert settings["name"].getStr == "test"

  block: # data without prologue key
    let data = %* {"name": "test"}
    let settings = newSettings(data = data, secretKey = "mykey")
    doAssert settings["prologue"]["secretKey"].getStr == "mykey"
    doAssert settings["name"].getStr == "test"

  block: # data without prologue key, secretKey generated
    let data = %* {"name": "test"}
    let settings = newSettings(data = data)
    doAssert settings["prologue"]["secretKey"].getStr.len == 8
    doAssert settings["name"].getStr == "test"

block: # newSettings explicit parameters
  let settings = newSettings(address = "127.0.0.1", port = Port(3000),
                             debug = false, reusePort = false, bufSize = 8192)
  doAssert settings.address == "127.0.0.1"
  doAssert settings.port.int == 3000
  doAssert settings.debug == false
  doAssert settings.reusePort == false
  doAssert settings.bufSize == 8192

block: # loadSettings preserves full data tree
  let data = %* {
    "prologue": {
      "secretKey": "testkey",
      "maxBody": 2_000,
      "appName": "myapp"
    },
    "custom": "value"
  }
  let settings = loadSettings(data)
  doAssert settings["prologue"]["maxBody"].getInt == 2_000
  doAssert settings["prologue"]["secretKey"].getStr == "testkey"
  doAssert settings["custom"].getStr == "value"
