# Package

version       = "0.1.6"
author        = "flywind"
description   = "Full-Stack Web Framework."
license       = "Apache-2.0"
srcDir        = "src"



# Dependencies
requires "nim >= 1.2.0"
requires "regex >= 0.13.1 & < 0.14.0"
requires "nimcrypto >= 0.4.11"
requires "cookies >= 0.1.0"

when not defined(windows):
  requires "httpbeast >= 0.2.2"

# # examples
# task helloworld, "helloworld":
#   exec "nim c -r examples/helloworld/app.nim"

# tests
task tests, "Run all tests":
  exec "testament cat /"

task examples, "Test examples":
  exec "testament r tests/test_compile/test_compile.nim"

task docs, "Only for gh-pages, not for users":
  exec "mkdocs build"
  exec "mkdocs gh-deploy"
