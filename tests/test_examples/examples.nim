import os, osproc, strformat


# Test Examples
block:
  let
    helloWorldDir = "./examples/helloworld"
    todolistDir = "./examples/todolist"
    todoappDir = "./examples/todoapp"
    blogDir = "./examples/blog"
    app = "app.nim"
    execCommand = "nim c --gc:arc --d:release --hints:off"

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
