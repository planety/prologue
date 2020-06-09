# Package

version       = "0.2.0"
author        = "flywind"
description   = "Full-Stack Web Framework."
license       = "Apache-2.0"
srcDir        = "src"



# Dependencies
requires "nim >= 1.2.0"
requires "regex >= 0.15.0"
requires "nimcrypto >= 0.4.11"
requires "karax >= 1.1.2"
requires "cookies >= 0.2.0"

when not defined(windows):
  requires "httpbeast >= 0.2.2"


# tests
task tests, "Run all tests":
  exec "testament cat /"

task examples, "Test examples":
  exec "testament r tests/test_examples/examples.nim"

task docs, "Only for gh-pages, not for users":
  exec "mkdocs build"
  exec "mkdocs gh-deploy"
