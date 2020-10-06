include ../../../src/prologue/core/nativesettings


block:
  let settings = newSettings()
  doAssert settings.address == ""
  doAssert settings.port.int == 8080
  doAssert settings.debug == true
  doAssert settings.reusePort == true
  doAssert settings.staticDirs.len == 0
  doAssert settings.appName.len == 0
  doAssert settings.bufSize == 40960

  doAssert settings.hasKey("secretKey")
  doAssert settings["secretKey"].getStr.len == 8
  doAssert settings.getOrDefault("secretKey").getStr == settings["secretKey"].getStr
  doAssert settings.getOrDefault("empty").getStr.len == 0
