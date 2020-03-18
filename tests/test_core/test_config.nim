import ../../src/prologue/core/configure


import unittest, os


suite "Test Config":
  let filename = "tests/.env"

  test "can write config":
    let
      env = initEnv()
    env.setPrologueEnv("debug", "true")
    env.setPrologueEnv("port", "8080")
    env.setPrologueEnv("appName", "Starlight")
    env.setPrologueEnv("staticDir", "static")
    writePrologueEnv(filename, env)
    check existsFile(filename)

  test "can load config":
    let env = loadPrologueEnv("tests/.env")
    check: 
      env["debug"] == "true"
      env["port"] == "8080"
      env["appName"] == "Starlight"
      env["staticDir"] == "static"

  if existsFile(filename):
    removeFile(filename)
