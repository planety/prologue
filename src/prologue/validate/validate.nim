import tables, strtabs, strutils, strformat

from ./basic import nil


type
  Info* = tuple[hasValue: bool, msg: string]
  ValidateHandler* = proc(text: string): Info {.closure.}

  FormValidation* = object
    data: OrderedTableRef[string, seq[ValidateHandler]]


proc newFormValidation*(validator: openArray[(string, seq[
    ValidateHandler])]): FormValidation {.inline.} =
  FormValidation(data: validator.newOrderedTable)

proc validate*(formValidation: FormValidation, textTable: StringTableRef,
    allMsgs = true): Info =
  var msgs = ""
  for (key, handlers) in formValidation.data.pairs:
    for handler in handlers:
      var
        hasValue: bool
        msg: string
      if not textTable.hasKey(key):
        hasValue = false
        msg = "Can't find key: " & key
      else:
        (hasValue, msg) = handler(textTable[key])
      if hasValue:
        continue
      msgs.add msg
      msgs.add "\n"
      if not allMsgs:
        return (false, msgs)

  if msgs.len != 0:
    return (false, msgs)
  return (true, msgs)

proc isInt*(msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    if basic.isInt(text):
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} is not an integer!")
    else:
      result = (false, msg)

proc isNumeric*(msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    if basic.isNumeric(text):
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} is not a number!")
    else:
      result = (false, msg)

proc isBool*(msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    if basic.isBool(text):
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} is not a boolean!")
    else:
      result = (false, msg)

proc minValue*(min: float, msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    var value: float
    try:
      value = parseFloat(text)
    except ValueError:
      return (false, fmt"{text} is not a number!")

    if value >= min:
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} is not greater than or equal to {min}!")
    else:
      result = (false, msg)

proc maxValue*(max: float, msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    var value: float
    try:
      value = parseFloat(text)
    except ValueError:
      return (false, fmt"{text} is not a number!")

    if value <= max:
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} is not less than or equal to {max}!")
    else:
      result = (false, msg)

proc inRange*(min, max: float, msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    var value: float
    try:
      value = parseFloat(text)
    except ValueError:
      return (false, fmt"{text} is not a number!")

    if value <= max and value >= min:
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} is not in range from {min} to {max}!")
    else:
      result = (false, msg)

proc equals*(value: string, msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    if text == value:
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} is not equal to {value}!")
    else:
      result = (false, msg)

proc accepted*(msg = ""): ValidateHandler {.inline.} =
  ## if lowerAscii input in {"yes", "on", "1", or "true"}, return true
  result = proc(text: string): Info =
    case text.toLowerAscii
    of "yes", "y", "on", "1", "true":
      result = (true, "")
    else:
      if msg.len == 0:
        result = (false, fmt"""{text} is not in "yes", "y", "on", "1", "true"!""")
      else:
        result = (false, msg)

proc required*(msg = ""): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    if text.len != 0:
      result = (true, "")
    elif msg.len == 0:
      result = (false, "Field is required!")
    else:
      result = (false, msg)
