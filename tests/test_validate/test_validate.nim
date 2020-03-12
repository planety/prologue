from ../../src/prologue/validate/validate import required


import unittest


suite "Test Validate":
  test "required can work":
    let
      msg = "Keywords required"
      decide = required(msg)
    check:
      decide("prologue") == (true, "")
      decide("") == (false, msg)
