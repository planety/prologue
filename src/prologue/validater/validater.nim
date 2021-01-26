# Copyright 2020 Zeshen Xing
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

## This module contains basic validation operations.
## 
## **The single text validation**
runnableExamples:
  import strtabs

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
## **Multiple texts validation**
runnableExamples:
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


import std/[tables, strtabs, strutils, strformat]

from ./basic import nil
from ../core/basicregex import match, re, Regex, RegexMatch


type
  Info* = tuple[hasValue: bool, msg: string]
  ValidateHandler* = proc(text: string): Info {.closure.}

  FormValidation* = object
    data: OrderedTableRef[string, seq[ValidateHandler]]


func newFormValidation*(validator: openArray[(string, seq[ValidateHandler])]
                        ): FormValidation {.inline.} =
  ## Creates a new ``Formvalidation``.
  FormValidation(data: validator.newOrderedTable)

proc validate*(formValidation: FormValidation, textTable: StringTableRef,
                allMsgs = true): Info =
  ## Validates all (key, value) pairs in ``textTable``.
  var msgs = ""
  for (key, handlers) in formValidation.data.pairs:
    for handler in handlers:
      var
        hasValue: bool
        msg: string
      if not textTable.hasKey(key):
        hasValue = false
        msgs.add &"Can't find key: {key}\n"
        if not allMsgs:
          return (false, msgs)
        break
      else:
        (hasValue, msg) = handler(textTable[key])
      if not hasValue:
        msgs.add &"{msg}\n"
        if not allMsgs:
          return (false, msgs)

  if msgs.len != 0:
    return (false, msgs)
  return (true, msgs)

func isInt*(msg = ""): ValidateHandler {.inline.} =
  ## The value of ``text`` is a int. If the length of 
  ## ``msg`` is more than 0, returns this ``msg`` when failed.
  result = func(text: string): Info =
    if basic.isInt(text):
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} is not an integer!")
    else:
      result = (false, msg)

func isNumeric*(msg = ""): ValidateHandler {.inline.} =
  ## The value of ``text`` is  a number. If the length of 
  ## ``msg`` is more than 0, returns this ``msg`` when failed.
  result = func(text: string): Info =
    if basic.isNumeric(text):
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} is not a number!")
    else:
      result = (false, msg)

func isBool*(msg = ""): ValidateHandler {.inline.} =
  ## The value of ``text`` is a bool. If the length of 
  ## ``msg`` is more than 0, returns this ``msg`` when failed.
  result = func(text: string): Info =
    if basic.isBool(text):
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} is not a Boolean!")
    else:
      result = (false, msg)

func minValue*(min: float, msg = ""): ValidateHandler {.inline.} =
  ## The value of ``text`` is more than or equal to ``min``. If the length of 
  ## ``msg`` is more than 0, returns this ``msg`` when failed.
  result = func(text: string): Info =
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

func maxValue*(max: float, msg = ""): ValidateHandler {.inline.} =
  ## The value of ``text`` is less than or equal to ``max``. If the length of 
  ## ``msg`` is more than 0, returns this ``msg`` when failed.
  result = func(text: string): Info =
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

func rangeValue*(min, max: float, msg = ""): ValidateHandler {.inline.} =
  ## The value of ``text`` is between ``min`` and ``max``. If the length of 
  ## ``msg`` is more than 0, returns this ``msg`` when failed.
  result = func(text: string): Info =
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

func minLength*(min: Natural, msg = ""): ValidateHandler {.inline.} =
  ## The length of ``text`` is more than or equal to ``min``. If the length of 
  ## ``msg`` is more than 0, returns this ``msg`` when failed.
  result = func(text: string): Info =
    let length = text.len
    if length >= min:
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"Length {length} is not greater than or equal to {min}!")
    else:
      result = (false, msg)

func maxLength*(max: Natural, msg = ""): ValidateHandler {.inline.} =
  ## The length of ``text`` is less than or equal to ``max``. If the length of 
  ## ``msg`` is more than 0, returns this ``msg`` when failed.
  result = func(text: string): Info =
    let length = text.len
    if length <= max:
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"Length {length} is not less than or equal to {max}!")
    else:
      result = (false, msg)

func rangeLength*(min, max: Natural, msg = ""): ValidateHandler {.inline.} =
  ## The length of ``text`` is between ``min`` and ``max``. If the length of 
  ## ``msg`` is more than 0, returns this ``msg`` when failed.
  result = func(text: string): Info =
    let length = text.len
    if length <= max and length >= min:
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"Length {length} is not in range from {min} to {max}!")
    else:
      result = (false, msg)

func equals*(value: string, msg = ""): ValidateHandler {.inline.} =
  ## The content of ``text`` is equal to ``value``. If the length of 
  ## ``msg`` is more than 0, returns this ``msg`` when failed.
  result = func(text: string): Info =
    if text == value:
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} is not equal to {value}!")
    else:
      result = (false, msg)

func accepted*(msg = ""): ValidateHandler {.inline.} =
  ## If lowerAscii input in {"yes", "on", "1", or "true"}, return true
  ## If the length of ``msg`` is more than 0, 
  ## returns this ``msg`` when failed.
  result = func(text: string): Info =
    case text.toLowerAscii
    of "yes", "y", "on", "1", "true":
      result = (true, "")
    else:
      if msg.len == 0:
        result = (false, fmt"""{text} is not in "yes", "y", "on", "1", "true"!""")
      else:
        result = (false, msg)

func required*(msg = ""): ValidateHandler {.inline.} =
  ## Succeeds if The content of ``text`` is not empty. If the length of 
  ## ``msg`` is more than 0, returns the ``msg`` when failed.
  result = func(text: string): Info =
    if text.len != 0:
      result = (true, "")
    elif msg.len == 0:
      result = (false, "Field is required!")
    else:
      result = (false, msg)

func matchRegex*(value: Regex, msg = ""): ValidateHandler {.inline.} =
  ## Succeeds if the content of ``text`` matches the regex expression. If the length of 
  ## ``msg`` is more than 0, returns the ``msg`` when failed.
  result = func(text: string): Info =
    var m: RegexMatch
    if text.match(value, m):
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} doesn't match Regex")
    else:
      result = (false, msg)

func matchURL*(msg = ""): ValidateHandler {.inline.} =
  ## Succeeds if the content of ``text`` matches the url expression. If the length of 
  ## ``msg`` is more than 0, returns the ``msg`` when failed.
  result = func(text: string): Info =
    var m: RegexMatch
    if text.match(re"(https?|ftp|file)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]", m):
      result = (true, "")
    elif msg.len == 0:
      result = (false, fmt"{text} doesn't match url")
    else:
      result = (false, msg)
