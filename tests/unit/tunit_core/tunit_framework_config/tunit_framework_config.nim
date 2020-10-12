import ../../../../src/prologue

import std/[os, json]


let cur = getCurrentDir()
setCurrentDir(parentDir(currentSourcePath()))

block:
  block:
    delEnv("PROLOGUE")

  block:
    putEnv("PROLOGUE", "debug")
    var app = newAppQueryEnv()

    doAssert app.gScope.settings.getOrDefault("name").getStr == "debug"

  block:
    putEnv("PROLOGUE", "production")
    var app = newAppQueryEnv()

    doAssert app.gScope.settings.getOrDefault("name").getStr == "production"
  
  block:
    putEnv("PROLOGUE", "custom")
    var app = newAppQueryEnv()

    doAssert app.gScope.settings.getOrDefault("name").getStr == "custom"

  block:
    putEnv("PROLOGUE", "default")
    var app = newAppQueryEnv()

    doAssert app.gScope.settings.getOrDefault("name").getStr == "default"

  block:
    delEnv("PROLOGUE")


setCurrentDir(cur)
