import std/[os, osproc, strformat]


# Test Examples
block:
  let
    todoappDir = "./examples/todoapp"
    app = "app.nim"
    execCommand = "nim c --d:release"

  # app can compile
  block:
    let (outp, errC) = execCmdEx(fmt"{execCommand} {todoappDir / app}")
    doAssert errC == 0, outp
