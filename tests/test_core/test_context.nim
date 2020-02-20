import ../../src/prologue/core/context

import unittest


suite "Test Context":
  test "multiMatch can work":
    check:
      multiMatch("/hello/{name}/ok/{age}/io", @{"name": "flywind",
        "age": "20"}) == "/hello/flywind/ok/20/io"
      multiMatch("/api/homepage") == "/api/homepage"
      multiMatch("", @{"name": "flywind"}) == ""
