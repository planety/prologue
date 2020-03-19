from ../../src/prologue/core/utils import isStaticFile


import unittest


suite "Tesst Utils":
  test "isStaticFile can work":
    let
      s1 = isStaticFile("tests/test_utils/static/css/basic.css", @["static", "tests"])
      s2 = isStaticFile("tests/test_utils/static/css/basic.css", @["tests"])
      s3 = isStaticFile("tests/test_utils/templates/basic.html", @["templates", "tests"])
      s4 = isStaticFile("tests/test_utils/temp/basic.html", @["templates", "static"])
    check:
      s1.hasValue
      s1.filename == "basic.css"
      s1.root == "tests/test_utils/static/css"
      s2.hasValue
      s2.filename == "basic.css"
      s2.root == "tests/test_utils/static/css"
      s3.hasValue
      s3.filename == "basic.html"
      s3.root == "tests/test_utils/templates"
      not s4.hasValue
      s4.filename.len == 0
      s4.root.len == 0
