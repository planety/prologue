# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.
import prologue

import unittest, os


suite "Test Config":
  let fileName = "tests/.env"
  if existsFile(fileName):
    removeFile(fileName)

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