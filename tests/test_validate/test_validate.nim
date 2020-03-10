from ../../src/prologue/validate/validate import required


import unittest


suite "Test Validate":
  test "required can work":
    let decide = required()
    check decide("prologue")
    check not decide("")
