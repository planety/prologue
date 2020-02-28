# Package

version       = "0.1.4"
author        = "flywind"
description   = "Medium Scale Web Framework."
license       = "BSD-3-Clause"
srcDir        = "src"



# Dependencies
# Nim support begin from v1.2
requires "nim >= 1.0.6"
requires "regex >= 0.13.1"
requires "nimcrypto >= 0.4.10"

# # examples
# task helloworld, "helloworld":
#   exec "nim c -r examples/helloworld/app.nim"

# tests
task test, "Run all tests":
  exec "nim c -r tests/alltests.nim"

task test_arc, "Run all tests with arc":
  exec "nim c -r --gc:arc tests/alltests.nim"

task docs, "Only for gh-pages, not for users":
  exec "mkdocs build"
  exec "mkdocs gh-deploy"
