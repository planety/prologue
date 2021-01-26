# Validation

`Prologue` provides lots of helper functions for validating data from users.

## Single Record

Each helper function could be used directly, for examples you want to check whether the content of a string is an int.

```nim
import prologue/validate/validate

let
  msg = "Int required"
  checkInt = isInt(msg)

doAssert checkInt("12") == (true, "")
doAssert checkInt("912.6) == (false, msg)
```

## Multiple Records

You could also check whether multiple records meets the requirements.

```nim
import prologue/validate/validate
import strtabs

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
```
