# Package

version       = "0.1.4"
author        = "flywind"
description   = "Another micro web framework."
license       = "BSD-3-Clause"
srcDir        = "src"



# Dependencies

requires "nim >= 1.0.0"
requires "regex >= 0.13.0"
requires "nimcrypto >= 0.4.9"

# # examples
# task helloworld, "helloworld":
#   exec "nim c -r examples/helloworld/app.nim"

# tests
task test, "Run all tests":
  exec "nim c -r tests/alltests.nim"

task test_arc, "Run all tests with arc":
  exec "nim c -r --gc:arc tests/alltests.nim"

task docs, "Only for gh-pages, not for users":
  exec "mkdocs gh-deploy"
