from ../../src/prologue/validate/validate import required, accepted, isInt,
    isNumeric, isBool


import unittest


suite "Test Validate":
  test "isInt can work":
    let
      msg = "Int required"
      decide = isInt(msg)
    check:
      decide("12") == (true, "")
      decide("-753") == (true, "")
      decide("0") == (true, "")
      decide("912.6") == (false, msg)
      decide("a912") == (false, msg)
      decide("") == (false, msg)

  test "isNumeric can work":
    let
      msg = "Numeric required"
      decide = isNumeric(msg)
    check:
      decide("12") == (true, "")
      decide("-753") == (true, "")
      decide("0") == (true, "")
      decide("0.5") == (true, "")
      decide("-912.6") == (true, "")
      decide("a912") == (false, msg)
      decide("0.91.2") == (false, msg)
      decide("") == (false, msg)

  test "isBool can work":
    let
      msg = "Bool required"
      decide = isBool(msg)
    check:
      decide("true") == (true, "")
      decide("1") == (true, "")
      decide("yes") == (true, "")
      decide("n") == (true, "")
      decide("False") == (true, "")
      decide("Off") == (true, "")
      decide("wrong") == (false, msg)
      decide("") == (false, msg)

  test "required can work":
    let
      msg = "Keywords required"
      decide = required(msg)
    check:
      decide("prologue") == (true, "")
      decide("") == (false, msg)

  test "accepted can work":
    let
      msg = "Not accepted"
      decide = accepted(msg)
    check:
      decide("on") == (true, "")
      decide("y") == (true, "")
      decide("1") == (true, "")
      decide("yes") == (true, "")
      decide("true") == (true, "")
      decide("") == (false, msg)
      decide("off") == (false, msg)
      decide("12") == (false, msg)
