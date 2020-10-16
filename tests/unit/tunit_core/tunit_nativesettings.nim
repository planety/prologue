include ../../../src/prologue/core/nativesettings


block:
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
