from ../../src/prologue/core/types import SecretKey, parseValue, `$`, 
    parseStringTable, isInt, isNumeric, isBool

import unittest, strtabs


suite "Test Is Utils":
  test "isInt can work":
    check isInt("12")
    check isInt("-753")
    check isInt("0")
    check not isInt("912.6")
    check not isInt("a912")
  
  test "isNumeric can work":
    check isNumeric("12")
    check isNumeric("-753")
    check isNumeric("0")
    check isNumeric("0.5")
    check isNumeric("-912.6")
    check not isNumeric("a912")
    check not isNumeric("0.91.2")

  test "isBool can work":
    check isBool("true")
    check isBool("1")
    check isBool("yes")
    check isBool("n")
    check isBool("False")
    check isBool("Off")


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
      parseValue("true", true) == true
      parseValue("s", false) == false

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
