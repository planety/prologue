import os, osproc, strformat


# Test Examples
block:
  let
    helloWorldDir = "./examples/helloworld"
    todolistDir = "./examples/todolist"
    todoappDir = "./examples/todoapp"
    blogDir = "./examples/blog"
    basicDir = "./examples/basic"
    app = "app.nim"
    execCommand = "nim c --d:release --hints:off"

  # helloworld can compile
  block:
    let (outp, errC) = execCmdEx(fmt"{execCommand} {helloWorldDir / app}")
    doAssert errC == 0, outp

  # todolist can compile
  block:
    let (outp, errC) = execCmdEx(fmt"{execCommand} {todolistDir / app}")
    doAssert errC == 0, outp

  # todoapp can compile
  block:
    let (outp, errC) = execCmdEx(fmt"{execCommand} {todoappDir / app}")
    doAssert errC == 0, outp

  # blog can compile
  block:
    let (outp, errC) = execCmdEx(fmt"{execCommand} {blogDir / app}")
    doAssert errC == 0, outp

  # basic can compile
  block:
    let (outp, errC) = execCmdEx(fmt"{execCommand} {basicDir / app}")
    doAssert errC == 0, outp
