import ../../../src/prologue/core/configure


import std/os


# "Test Config"
block:
  let filename = "tests/.env"

  # "can write config"
  block:
    let
      env = initEnv()
    env.setPrologueEnv("debug", "true")
    env.setPrologueEnv("port", "8080")
    env.setPrologueEnv("appName", "Prologue")
    env.setPrologueEnv("staticDir", "static")
    writePrologueEnv(filename, env)
    doAssert fileExists(filename)

  # "can load config"
  block:
    let env = loadPrologueEnv(filename)
    doAssert env["debug"] == "true"
    doAssert env["port"] == "8080"
    doAssert env["appName"] == "Prologue"
    doAssert env["staticDir"] == "static"
    doAssert env.getOrDefault("address", "127.0.0.2") == "127.0.0.2"

  if fileExists(filename):
    removeFile(filename)
