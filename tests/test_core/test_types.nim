from ../../src/prologue/core/types import SecretKey, parseValue, `$`,
    parseStringTable

import unittest, strtabs


suite "Test Parse Utils":
  test "can parse int":
    check:
      parseValue("12", 3) == 12
      parseValue("x", 1) == 1

  test "can parse float":
    check:
      parseValue("12.5", 3.4) == 12.5
      parseValue("z", 1.4) == 1.4

  test "can parse bool":
    check:
      parseValue("true", true)
      not parseValue("s", false)

  test "can parse string":
    check parseValue("fight", "") == "fight"


suite "Test Secret Key":
  test "can hide secret key":
    let secretKey = SecretKey("PrologueSecretKey")
    check $secretKey == "SecretKey(********)"

  test "can expose secret key":
    let secretKey = SecretKey("PrologueSecretKey")
    check string(secretKey) == "PrologueSecretKey"


suite "Deserialize StringTable":
  test "can parse stringTable from empty stringTable":
    let tabs = newStringTable()
    check $parseStringTable($(tabs)) == $tabs

  test "can parse stringTable from stringTable with elements":
    let tabs = {"username": "flywind", "password": "root"}.newStringTable()
    check $parseStringTable($tabs) == $tabs

  test "can parse stringTable from stringTable with empty value":
    let tabs = {"username": "flywind", "password": "",
        "day": "one"}.newStringTable()
    check $parseStringTable($tabs) == $tabs

  test "can parse stringTable from stringTable with empty key":
    let tabs = {"username": "flywind", "password": "root",
        "": "one"}.newStringTable()
    check $parseStringTable($tabs) == $tabs

  test "can parse stringTable from stringTable with space key or value":
    let tabs = {"user    name": "   flywind", "password": " ro  ot  ",
        "": "    o ne"}.newStringTable()
    check $parseStringTable($tabs) == $tabs
