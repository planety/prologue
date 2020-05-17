import os, osproc, strformat


# Test Examples
block:
  let
    helloWorldDir = "./examples/helloworld"
    todolistDir = "./examples/todolist"
    todoappDir = "./examples/todoapp"
    blogDir = "./examples/blog"
    app = "app.nim"

  # helloworld can compile
  block:
    let (outp, errC) = execCmdEx(fmt"nim c --hints:off {helloWorldDir / app}")
    doAssert errC == 0, outp

  # todolist can compile
  block:
    let (outp, errC) = execCmdEx(fmt"nim c --hints:off {todolistDir / app}")
    doAssert errC == 0, outp

  # todoapp can compile
  block:
    let (outp, errC) = execCmdEx(fmt"nim c --hints:off {todoappDir / app}")
    doAssert errC == 0, outp

  # blog can compile
  block:
    let (outp, errC) = execCmdEx(fmt"nim c --hints:off {blogDir / app}")
    doAssert errC == 0, outp
