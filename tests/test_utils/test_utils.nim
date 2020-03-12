from ../../src/prologue/core/utils import isStaticFile


import unittest


suite "Tesst Utils":
  test "isStaticFile can work":
    let
      s1 = isStaticFile("static/css/basic.css", @["templates", "static"])
      s2 = isStaticFile("/static/css/basic.css", @["templates", "static"])
      s3 = isStaticFile("/templates/basic.html", @["templates", "static"])
      s4 = isStaticFile("/temp/basic.html", @["templates", "static"])
    check:
      s1.hasValue
      s1.fileName == "basic.css"
      s1.root == "static/css"
      s2.hasValue
      s2.fileName == "basic.css"
      s2.root == "static/css"
      s3.hasValue
      s3.fileName == "basic.html"
      s3.root == "templates"
      not s4.hasValue
      s4.fileName.len == 0
      s4.root.len == 0
