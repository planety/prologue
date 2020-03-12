from ../../src/prologue/validate/basic import isInt, isNumeric, isBool

import unittest


suite "Test Is Utils":
  test "isInt can work":
    check:
      isInt("12")
      isInt("-753")
      isInt("0")
      not isInt("912.6")
      not isInt("a912")

  test "isNumeric can work":
    check:
      isNumeric("12")
      isNumeric("-753")
      isNumeric("0")
      isNumeric("0.5")
      isNumeric("-912.6")
      not isNumeric("a912")
      not isNumeric("0.91.2")

  test "isBool can work":
    check:
      isBool("true")
      isBool("1")
      isBool("yes")
      isBool("n")
      isBool("False")
      isBool("Off")
      not isBool("wrong")