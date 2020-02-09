import prologue / types

import unittest


suite "Test Types":
  test "can parse int":
    check parseValue("12", 3) == 12
    check parseValue("x", 1) == 1
  
  test "can parse float":
    check parseValue("12.5", 3.4) == 12.5
    check parseValue("z", 1.4) == 1.4

  test "can parse bool":
    check parseValue("true", true) == true
    check parseValue("s", false) == false

  test "can parse string":
    check parseValue("fight", "") == "fight"

  test "can hide secret key":
    let secretKey = SecretKey("PrologueSecretKey")
    check $secretKey == "SecretKey(********)"
  
  test "can expose secret key":
    let secretKey = SecretKey("PrologueSecretKey")
    check string(secretKey) == "PrologueSecretKey"
