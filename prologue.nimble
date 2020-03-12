# Package

version       = "0.1.4"
author        = "flywind"
description   = "Full-Stack Web Framework."
license       = "Apache-2.0"
srcDir        = "src"



# Dependencies
# Nim support begin from v1.2
requires "nim >= 1.0.0"
requires "regex >= 0.13.1"
requires "nimcrypto >= 0.4.10"

when not defined(windows):
  requires "httpbeast >= 0.2.2"

# # examples
# task helloworld, "helloworld":
#   exec "nim c -r examples/helloworld/app.nim"

# tests
task test, "Run all tests":
  exec "nim c -r tests/alltests.nim"

task test_std, "Run all tests use asynchttpserver":
  exec "nim c -r -d:usestd tests/alltests.nim"

task test_arc, "Run all tests with arc":
  exec "nim c -r --gc:arc tests/alltests.nim"

task docs, "Only for gh-pages, not for users":
  exec "mkdocs build"
  exec "mkdocs gh-deploy"
