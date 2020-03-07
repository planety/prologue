from ../../src/prologue/core/utils import isStaticFile


import unittest


suite "Tesst Utils":
  test "isStaticFile can work":
    let 
      s1 = isStaticFile("static/css/basic.css", @["templates", "static"])
      s2 = isStaticFile("/static/css/basic.css", @["templates", "static"])
      s3 = isStaticFile("/templates/basic.html", @["templates", "static"])
      s4 = isStaticFile("/temp/basic.html", @["templates", "static"])
    check s1.hasValue
    check s1.fileName == "basic.css"
    check s1.root == "static/css"
    check s2.hasValue
    check s2.fileName == "basic.css"
    check s2.root == "static/css"
    check s3.hasValue
    check s3.fileName == "basic.html"
    check s3.root == "templates"
    check not s4.hasValue
    check s4.fileName.len == 0
    check s4.root.len == 0
