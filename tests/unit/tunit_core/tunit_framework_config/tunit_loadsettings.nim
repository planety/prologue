import ../../../../src/prologue

import std/[os, json]

let cur = getCurrentDir()
setCurrentDir(parentDir(currentSourcePath()))


block:
  block:
    var app = newApp(loadSettings(".config/config.debug.json"))

    doAssert app.gScope.settings.getOrDefault("name").getStr == "debug"

  block:
    var app = newApp(loadSettings(".config/config.json"))

    doAssert app.gScope.settings.getOrDefault("name").getStr == "default"

  block:
    var app = newApp(loadSettings(".config/config.custom.json"))

    doAssert app.gScope.settings.getOrDefault("name").getStr == "custom"

  block:
    var app = newApp(loadSettings(".config/config.production.json"))

    doAssert app.gScope.settings.getOrDefault("name").getStr == "production"


setCurrentDir(cur)
