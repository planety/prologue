import prologue / utils

import unittest


suite "Test Utils":
  test "can parse PathParams":
    check parsePathParams("name:int") == ("name", "int")
    check parsePathParams("name:float") == ("name", "float")
    check parsePathParams("name:path") == ("name", "path")
    check parsePathParams("name:") == ("name", "str")
    check parsePathParams("name") == ("name", "str")
