discard """
  cmd:      "nim c -r --styleCheck:hint --panics:on $options $file"
  matrix:   "--gc:arc; --gc:arc --d:release"
  targets:  "c"
  nimout:   ""
  action:   "run"
  exitcode: 0
  timeout:  60.0
"""

import ../../src/prologue/core/form
import tables, os, strutils

let testmime = open(getAppDir() / "testmime.txt", fmRead).readAll()
let testfile = open(getAppDir() / "testfile.txt", fmRead).readAll()
let contenttype = "multipart/form-data; boundary=---------------------------203238422770489380538321896"
let formPart = parseFormPart(testmime, contenttype)
doAssert formPart.data["upload"].body.len == testfile.len
doAssert formPart.data["upload"].body == testfile
doAssert parseInt(formPart.data["howLongValid"].body) == 3600