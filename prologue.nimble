# Package

version       = "0.1.0"
author        = "flywind"
description   = "Another micro web framework."
license       = "MIT"
srcDir        = "src"



# Dependencies

requires "nim >= 1.0.0"

# # examples
# task helloworld, "helloworld":
#   exec "nim c -r examples/helloworld/app.nim"

# tests
task test, "Run all tests":
  exec "nim c -r tests/alltests.nim"

task test_arc, "Run all tests with arc":
  exec "nim c -r --gc:arc tests/alltests.nim"
