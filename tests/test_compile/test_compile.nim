import os, osproc, strformat


# Test Examples
block:
  let
    todoappDir = "./examples/todoapp"
    app = "app.nim"

  # todoapp can compile
  block:
    let (outp, errC) = execCmdEx(fmt"nim c --hints:off {todoappDir / app}")
    doAssert errC == 0, outp
