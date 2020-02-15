# To run these tests, simply execute `nimble test`.
import prologue/core/configure

import unittest, os


suite "Test Config":
  let fileName = "tests/.env"

  test "can write config":
    let 
      env = initEnv()
    env.setPrologueEnv("debug", "true")
    env.setPrologueEnv("port", "8080")
    env.setPrologueEnv("appName", "Starlight")
    env.setPrologueEnv("staticDir", "static")
    writePrologueEnv(fileName, env)
    check existsFile(fileName)

  test "can load config":
    let env = loadPrologueEnv("tests/.env")
    check $env == """{"debug": "true", "port": "8080", "appName": "Starlight", "staticDir": "static"}"""
    
  if existsFile(fileName):
    removeFile(fileName)