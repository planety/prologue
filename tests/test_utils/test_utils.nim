from ../../src/prologue/core/utils import isStaticFile
import os


# "Tesst Utils"
block:
  # "isStaticFile can work"
  block:
    let
      s1 = isStaticFile("tests/test_utils/static/css/basic.css", @["static", "tests"])
      s2 = isStaticFile("tests/test_utils/static/css/basic.css", @["tests"])
      s3 = isStaticFile("tests/test_utils/templates/basic.html", @["templates", "tests"])
      s4 = isStaticFile("tests/test_utils/temp/basic.html", @["templates", "static"])

    doAssert s1.hasValue
    doAssert s1.filename == "basic.css"
    doAssert s1.dir == normalizedPath("tests/test_utils/static/css")
    doAssert s2.hasValue
    doAssert s2.filename == "basic.css"
    doAssert s2.dir == normalizedPath("tests/test_utils/static/css")
    doAssert s3.hasValue
    doAssert s3.filename == "basic.html"
    doAssert s3.dir == normalizedPath("tests/test_utils/templates")
    doAssert not s4.hasValue
    doAssert s4.filename.len == 0
    doAssert s4.dir.len == 0

# "Tesst Utils"
block:
  # "isStaticFile can work"
  block:
    let
      s1 = isStaticFile("/tests///test_utils////static/////css////basic.css", @["/static", "tests"])
      s2 = isStaticFile("///////////tests/test_utils/static/css/basic.css", @["tests"])
      s3 = isStaticFile("//tests/test_utils/templates///////basic.html", @["//templates", "tests"])
      s4 = isStaticFile("tests/test_utils/temp/basic.html", @["templates", "static"])

    doAssert s1.hasValue
    doAssert s1.filename == "basic.css"
    doAssert s1.dir == normalizedPath("tests/test_utils/static/css")
    doAssert s2.hasValue
    doAssert s2.filename == "basic.css"
    doAssert s2.dir == normalizedPath("tests/test_utils/static/css")
    doAssert s3.hasValue
    doAssert s3.filename == "basic.html"
    doAssert s3.dir == normalizedPath("tests/test_utils/templates")
    doAssert not s4.hasValue
    doAssert s4.filename.len == 0
    doAssert s4.dir.len == 0
