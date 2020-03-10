import tables, strtabs, strutils


type
  Info* = tuple[hasValue: bool, msg: string]
  ValidateHandler* = proc(text: string): Info {.closure.}

  FormValidation* = object
    data: OrderedTableRef[string, seq[ValidateHandler]]


proc newFormValidation*(validator: openArray[(string, seq[ValidateHandler])]): FormValidation {.inline.} =
  FormValidation(data: validator.newOrderedTable)

proc validate*(formValidation: FormValidation, textTable: StringTableRef, allMsgs = true): Info =
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

proc accepted*(msg: string = "Can't accept this value!"): ValidateHandler {.inline.} =
  ## if lowerAscii input in {"yes", "on", "1", or "true"}, return true
  result = proc(text: string): Info =
    case text.toLowerAscii
    of "yes":
      return (true, "")
    of "on":
      return (true, "")
    of "1":
      return (true, "")
    of "true":
      return (true, "")
    else:
      return (false, msg)
    
proc required*(msg: string): ValidateHandler {.inline.} =
  result = proc(text: string): Info =
    if text.len != 0:
      result = (true, "")
    else:
      result = (false, msg)
