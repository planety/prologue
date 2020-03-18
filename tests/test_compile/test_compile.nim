import os, osproc, strformat

import unittest


suite "Test Examples":
  let
    helloWorldDir = "./examples/helloworld"
    todolistDir = "./examples/todolist"
    todoappDir = "./examples/todoapp"
    blogDir = "./examples/blog"
    app = "app.nim"

  test "helloworld can compile":
    let (_, errC) = execCmdEx(fmt"nim c --hints:off {helloWorldDir / app}")
    check errC == 0

  test "todolist can compile":
    let (_, errC) = execCmdEx(fmt"nim c --hints:off {todolistDir / app}")
    check errC == 0

  test "todoapp can compile":
    let (_, errC) = execCmdEx(fmt"nim c --hints:off {todoappDir / app}")
    check errC == 0

  test "blog can compile":
    let (_, errC) = execCmdEx(fmt"nim c --hints:off {blogDir / app}")
    check errC == 0
