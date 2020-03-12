from ../../src/prologue/validate/validate import required, accepted, isInt,
    isNumeric, isBool, equals, minValue, maxValue, inRange


import unittest


suite "Test Validate":
  test "isInt can work":
    let
      msg = "Int required"
      decide = isInt(msg)
      decideDefaultMsg = isInt()
    check:
      decide("12") == (true, "")
      decide("-753") == (true, "")
      decide("0") == (true, "")
      decide("912.6") == (false, msg)
      decide("a912") == (false, msg)
      decide("") == (false, msg)
      decideDefaultMsg("a912") == (false, "a912 is not an integer!")
      decideDefaultMsg("") == (false, " is not an integer!")

  test "isNumeric can work":
    let
      msg = "Numeric required"
      decide = isNumeric(msg)
      decideDefaultMsg = isNumeric()
    check:
      decide("12") == (true, "")
      decide("-753") == (true, "")
      decide("0") == (true, "")
      decide("0.5") == (true, "")
      decide("-912.6") == (true, "")
      decide("a912") == (false, msg)
      decide("0.91.2") == (false, msg)
      decide("") == (false, msg)
      decideDefaultMsg("0.91.2") == (false, "0.91.2 is not a number!")
      decideDefaultMsg("") == (false, " is not a number!")

  test "isBool can work":
    let
      msg = "Bool required"
      decide = isBool(msg)
      decideDefaultMsg = isBool()
    check:
      decide("true") == (true, "")
      decide("1") == (true, "")
      decide("yes") == (true, "")
      decide("n") == (true, "")
      decide("False") == (true, "")
      decide("Off") == (true, "")
      decide("wrong") == (false, msg)
      decide("") == (false, msg)
      decideDefaultMsg("wrong") == (false, "wrong is not a boolean!")
      decideDefaultMsg("") == (false, " is not a boolean!")

  test "equals can work":
    let
      msg = "not equal"
      decide = equals("prologue", msg)
      decideDefaultMsg = equals("starlight")
    check:
      decide("prologue") == (true, "")
      decide("") == (false, msg)
      decideDefaultMsg("prologue") == (false, "prologue is not equal to starlight!")

  test "minValue can work":
    let
      msg = "lower than"
      decide = minValue(12, msg)
      decideDefaultMsg = minValue(-5.5)
    check:
      decide("27") == (true, "")
      decide("8.5") == (false, msg)
      decide("abc") == (false, "abc is not a number!")
      decideDefaultMsg("") == (false, " is not a number!")
      decideDefaultMsg("-12") == (false, "-12 is not greater than or equal to -5.5!")

  test "maxValue can work":
    let
      msg = "greater than"
      decide = maxValue(12, msg)
      decideDefaultMsg = maxValue(-5.5)
    check:
      decide("2.7") == (true, "")
      decide("18.5") == (false, msg)
      decide("abc") == (false, "abc is not a number!")
      decideDefaultMsg("") == (false, " is not a number!")
      decideDefaultMsg("2") == (false, "2 is not less than or equal to -5.5!")

  test "inRange can work":
    let
      msg = "not inRange"
      decide = inRange(-9, 13, msg)
      decideDefaultMsg = inRange(-5.5, 77)
    check:
      decide("2.7") == (true, "")
      decide("18.5") == (false, msg)
      decide("abc") == (false, "abc is not a number!")
      decideDefaultMsg("") == (false, " is not a number!")
      decideDefaultMsg("-29") == (false, "-29 is not in range from -5.5 to 77.0!")

  test "required can work":
    let
      msg = "Keywords required"
      decide = required(msg)
      decideDefaultMsg = required()
    check:
      decide("prologue") == (true, "")
      decide("") == (false, msg)
      decideDefaultMsg("") == (false, "Field is required!")

  test "accepted can work":
    let
      msg = "Not accepted"
      decide = accepted(msg)
      decideDefaultMsg = accepted()
    check:
      decide("on") == (true, "")
      decide("y") == (true, "")
      decide("1") == (true, "")
      decide("yes") == (true, "")
      decide("true") == (true, "")
      decide("") == (false, msg)
      decide("off") == (false, msg)
      decide("12") == (false, msg)
      decideDefaultMsg("") == (false,""" is not in "yes", "y", "on", "1", "true"!""")
      decideDefaultMsg("off") == (false, """off is not in "yes", "y", "on", "1", "true"!""")
      decideDefaultMsg("12") == (false, """12 is not in "yes", "y", "on", "1", "true"!""")
