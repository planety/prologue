include ../../../src/prologue/core/context

# "Test Context"
block:
  # "multiMatch can work"

  doAssert multiMatch("/hello/{name}/ok/{age}/io", @{"name": "flywind",
                      "age": "20"}) == "/hello/flywind/ok/20/io"
  doAssert multiMatch("/api/homepage") == "/api/homepage"
  doAssert multiMatch("", @{"name": "flywind"}) == ""
