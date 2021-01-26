from ../../../src/prologue/validater/basic import isInt, isNumeric, isBool


# "Test Is Utils"
block:
  # "isInt can work"
  block:
    doAssert isInt("12")
    doAssert isInt("-753")
    doAssert isInt("0")
    doAssert not isInt("")
    doAssert not isInt("912.6")
    doAssert not isInt("a912")

  # "isNumeric can work"
  block:
    doAssert isNumeric("12")
    doAssert isNumeric("-753")
    doAssert isNumeric("0")
    doAssert isNumeric("0.5")
    doAssert isNumeric("-912.6")
    doAssert not isNumeric("")
    doAssert not isNumeric("a912")
    doAssert not isNumeric("0.91.2")

  # "isBool can work"
  block:
    doAssert isBool("true")
    doAssert isBool("1")
    doAssert isBool("yes")
    doAssert isBool("n")
    doAssert isBool("False")
    doAssert isBool("Off")
    doAssert not isBool("")
    doAssert not isBool("wrong")