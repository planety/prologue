import strtabs

from ../../../src/prologue/validater import required, accepted, isInt,
    isNumeric, isBool, equals, minValue, maxValue, rangeValue, matchRegex,
        matchUrl, newFormValidation, validate, minLength, maxLength, rangeLength

from ../../../src/prologue/core/basicregex import re


# "Test Validate"
block:
  # "isInt can work"
  block:
    let
      msg = "Int required"
      decide = isInt(msg)
      decideDefaultMsg = isInt()

    doAssert decide("12") == (true, "")
    doAssert decide("-753") == (true, "")
    doAssert decide("0") == (true, "")
    doAssert decide("912.6") == (false, msg)
    doAssert decide("a912") == (false, msg)
    doAssert decide("") == (false, msg)
    doAssert decideDefaultMsg("a912") == (false, "a912 is not an integer!")
    doAssert decideDefaultMsg("") == (false, " is not an integer!")

  # "isNumeric can work"
  block:
    let
      msg = "Numeric required"
      decide = isNumeric(msg)
      decideDefaultMsg = isNumeric()

    doAssert decide("12") == (true, "")
    doAssert decide("-753") == (true, "")
    doAssert decide("0") == (true, "")
    doAssert decide("0.5") == (true, "")
    doAssert decide("-912.6") == (true, "")
    doAssert decide("a912") == (false, msg)
    doAssert decide("0.91.2") == (false, msg)
    doAssert decide("") == (false, msg)
    doAssert decideDefaultMsg("0.91.2") == (false, "0.91.2 is not a number!")
    doAssert decideDefaultMsg("") == (false, " is not a number!")

  # "isBool can work"
  block:
    let
      msg = "Bool required"
      decide = isBool(msg)
      decideDefaultMsg = isBool()

    doAssert decide("true") == (true, "")
    doAssert decide("1") == (true, "")
    doAssert decide("yes") == (true, "")
    doAssert decide("n") == (true, "")
    doAssert decide("False") == (true, "")
    doAssert decide("Off") == (true, "")
    doAssert decide("wrong") == (false, msg)
    doAssert decide("") == (false, msg)
    doAssert decideDefaultMsg("wrong") == (false, "wrong is not a Boolean!")
    doAssert decideDefaultMsg("") == (false, " is not a Boolean!")

  # "equals can work"
  block:
    let
      msg = "not equal"
      decide = equals("prologue", msg)
      decideDefaultMsg = equals("starlight")

    doAssert decide("prologue") == (true, "")
    doAssert decide("") == (false, msg)
    doAssert decideDefaultMsg("prologue") == (false, "prologue is not equal to starlight!")

  # "minValue can work"
  block:
    let
      msg = "lower than"
      decide = minValue(12, msg)
      decideDefaultMsg = minValue(-5.5)

    doAssert decide("27") == (true, "")
    doAssert decide("8.5") == (false, msg)
    doAssert decide("abc") == (false, "abc is not a number!")
    doAssert decideDefaultMsg("") == (false, " is not a number!")
    doAssert decideDefaultMsg("-12") == (false, "-12 is not greater than or equal to -5.5!")

  # "maxValue can work"
  block:
    let
      msg = "greater than"
      decide = maxValue(12, msg)
      decideDefaultMsg = maxValue(-5.5)

    doAssert decide("2.7") == (true, "")
    doAssert decide("18.5") == (false, msg)
    doAssert decide("abc") == (false, "abc is not a number!")
    doAssert decideDefaultMsg("") == (false, " is not a number!")
    doAssert decideDefaultMsg("2") == (false, "2 is not less than or equal to -5.5!")

  # "rangeValue can work"
  block:
    let
      msg = "not in Range"
      decide = rangeValue(-9, 13, msg)
      decideDefaultMsg = rangeValue(-5.5, 77)

    doAssert decide("2.7") == (true, "")
    doAssert decide("18.5") == (false, msg)
    doAssert decide("abc") == (false, "abc is not a number!")
    doAssert decideDefaultMsg("") == (false, " is not a number!")
    doAssert decideDefaultMsg("-29") == (false, "-29 is not in range from -5.5 to 77.0!")

  # "minLength can work"
  block:
    let
      msg = "lower than"
      decide = minLength(12, msg)
      decideDefaultMsg = minLength(7)

    doAssert decide("Welcome to use Prologue!") == (true, "")
    doAssert decide("Not True") == (false, msg)
    doAssert decideDefaultMsg("Prologue") == (true, "")
    doAssert decideDefaultMsg("Not") == (false, "Length 3 is not greater than or equal to 7!")

  # "maxLength can work"
  block:
    let
      msg = "greater than"
      decide = maxLength(12, msg)
      decideDefaultMsg = maxLength(5)

    doAssert decide("True") == (true, "")
    doAssert decide("Welcome to use Prologue!") == (false, msg)
    doAssert decideDefaultMsg("True") == (true, "")
    doAssert decideDefaultMsg("Prologue") == (false, "Length 8 is not less than or equal to 5!")

  # "rangeLength can work"
  block:
    let
      msg = "not in Range"
      decide = rangeLength(9, 13, msg)
      decideDefaultMsg = rangeLength(5, 17)

    doAssert decide("use Prologue") == (true, "")
    doAssert decide("Prologue") == (false, msg)
    doAssert decideDefaultMsg("prologue") == (true, "")
    doAssert decideDefaultMsg("use") == (false, "Length 3 is not in range from 5 to 17!")

  # "required can work"
  block:
    let
      msg = "Keywords required"
      decide = required(msg)
      decideDefaultMsg = required()

    doAssert decide("prologue") == (true, "")
    doAssert decide("") == (false, msg)
    doAssert decideDefaultMsg("") == (false, "Field is required!")

  # "accepted can work"
  block:
    let
      msg = "Not accepted"
      decide = accepted(msg)
      decideDefaultMsg = accepted()

    doAssert decide("on") == (true, "")
    doAssert decide("y") == (true, "")
    doAssert decide("1") == (true, "")
    doAssert decide("yes") == (true, "")
    doAssert decide("true") == (true, "")
    doAssert decide("") == (false, msg)
    doAssert decide("off") == (false, msg)
    doAssert decide("12") == (false, msg)
    doAssert decideDefaultMsg("") == (false, """ is not in "yes", "y", "on", "1", "true"!""")
    doAssert decideDefaultMsg("off") == (false, """off is not in "yes", "y", "on", "1", "true"!""")
    doAssert decideDefaultMsg("12") == (false, """12 is not in "yes", "y", "on", "1", "true"!""")

  # "matchRegex can work"
  block:
    let
      msg = "Regex doesn't match!"
      decide = matchRegex(re"(?P<greet>hello) (?:(?P<who>[^\s]+)\s?)+", msg)
      decideDefaultMsg = matchRegex(re"abc")

    doAssert decide("hello beautiful world") == (true, "")
    doAssert decide("time") == (false, msg)
    doAssert decideDefaultMsg("abc") == (true, "")
    doAssert decideDefaultMsg("abcd") == (false, "abcd doesn't match Regex")

  # "matchUrl can work"
  block:
    let
      msg = "Regex doesn't match!"
      decide = matchUrl(msg)
      decideDefaultMsg = matchUrl()

    doAssert decide("https://www.google.com") == (true, "")
    doAssert decide("https://127.0.0.1") == (true, "")
    doAssert decide("127.0.0.1") == (false, msg)
    doAssert decideDefaultMsg("file:///prologue/starlight.nim") == (true, "")
    doAssert decideDefaultMsg("https:/www.prologue.com") == (false,
                "https:/www.prologue.com doesn't match url")

  # "validate can work"
  block:
    var form = newFormValidation({
        "accepted": @[required(), accepted()],
        "required": @[required()],
        "requiredInt": @[required(), isInt()],
        "minValue": @[required(), isInt(), minValue(12), maxValue(19)]
      })
    let
      chk1 = form.validate({"required": "on", "accepted": "true",
          "requiredInt": "12", "minValue": "15"}.newStringTable)
      chk2 = form.validate({"requird": "on", "time": "555",
          "minValue": "10"}.newStringTable)
      chk3 = form.validate({"requird": "on", "time": "555",
          "minValue": "10"}.newStringTable, allMsgs = false)
      chk4 = form.validate({"required": "on", "accepted": "true",
      "requiredInt": "12.5", "minValue": "13"}.newStringTable, allMsgs = false)

    doAssert chk1 == (true, "")
    doAssert not chk2.hasValue
    doAssert chk2.msg == "Can\'t find key: accepted\nCan\'t find key: " &
            "required\nCan\'t find key: requiredInt\n10 is not greater than or equal to 12.0!\n"
    doAssert not chk3.hasValue
    doAssert chk3.msg == "Can\'t find key: accepted\n"
    doAssert not chk4.hasValue
    doAssert chk4.msg == "12.5 is not an integer!\n"
