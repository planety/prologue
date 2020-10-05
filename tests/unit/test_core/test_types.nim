from ../../../src/prologue/core/types import SecretKey, parseValue, `$`,
    parseStringTable


import strtabs


# "Test Parse Utils"
block:
  # "can parse int"
  block:
    doAssert parseValue("12", 3) == 12
    doAssert parseValue("x", 1) == 1

  # "can parse float"
  block:
    doAssert parseValue("12.5", 3.4) == 12.5
    doAssert parseValue("z", 1.4) == 1.4

  # "can parse bool"
  block:
    doAssert parseValue("true", true)
    doAssert not parseValue("s", false)

  # "can parse string"
  block:
    doAssert parseValue("fight", "") == "fight"


# "Test Secret Key"
block:
  # "can hide secret key"
  block:
    let secretKey = SecretKey("PrologueSecretKey")
    doAssert $secretKey == "SecretKey(********)"

  # "can expose secret key"
  block:
    let secretKey = SecretKey("PrologueSecretKey")
    doAssert string(secretKey) == "PrologueSecretKey"


# "Deserialize StringTable"
block:
  # "can parse stringTable from empty stringTable"
  block:
    let tabs = newStringTable(mode = modeCaseSensitive)
    var newTabs = newStringTable(mode = modeCaseSensitive)
    parseStringTable(newTabs, $tabs)
    doAssert $newTabs == $tabs

  # "can parse stringTable from stringTable with elements"
  block:
    let tabs = {"username": "flywind", "password": "root"}.newStringTable()
    var newTabs = newStringTable(mode = modeCaseSensitive)
    parseStringTable(newTabs, $tabs)
    doAssert $newTabs == $tabs

  # "can parse stringTable from stringTable with empty value"
  block:
    let tabs = {"username": "flywind", "password": "",
        "day": "one"}.newStringTable()
    var newTabs = newStringTable(mode = modeCaseSensitive)
    parseStringTable(newTabs, $tabs)
    doAssert $newTabs == $tabs

  # "can parse stringTable from stringTable with empty key"
  block:
    let tabs = {"username": "flywind", "password": "root",
        "": "one"}.newStringTable()
    var newTabs = newStringTable(mode = modeCaseSensitive)
    parseStringTable(newTabs, $tabs)
    doAssert $newTabs == $tabs

  # "can parse stringTable from stringTable with space key or value"
  block:
    let tabs = {"user    name": "   flywind", "password": " ro  ot  ",
        "": "    o ne"}.newStringTable()
    var newTabs = newStringTable(mode = modeCaseSensitive)
    parseStringTable(newTabs, $tabs)
    doAssert $newTabs == $tabs
