# Package

version       = "0.1.6"
author        = "flywind"
description   = "Full-Stack Web Framework."
license       = "Apache-2.0"
srcDir        = "src"



# Dependencies
# Nim support begin from v1.2
requires "nim >= 1.2.0"
requires "regex >= 0.13.1 & < 0.14.0"
requires "nimcrypto >= 0.4.11"

when not defined(windows):
  requires "httpbeast >= 0.2.2"

# # examples
# task helloworld, "helloworld":
#   exec "nim c -r examples/helloworld/app.nim"

# tests
task tests, "Run all tests":
  exec "nim c -r tests/test_all.nim"

task examples, "Test examples":
  exec "nim c -r tests/test_compile/test_compile.nim"

task test_std, "Run all tests use asynchttpserver":
  exec "nim c -r -d:usestd tests/test_all.nim"

task docs, "Only for gh-pages, not for users":
  exec "mkdocs build"
  exec "mkdocs gh-deploy"
