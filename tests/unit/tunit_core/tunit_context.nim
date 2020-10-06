include ../../../src/prologue/core/context


# "Test Context"
block:
  # "multiMatch can work"
  # TODO support wildcard

  doAssert multiMatch("/hello/{name}/ok/{age}/io", @{"name": "flywind",
                      "age": "20"}) == "/hello/flywind/ok/20/io"
  doAssert multiMatch("/api/homepage") == "/api/homepage"
  doAssert multiMatch("", @{"name": "flywind"}) == ""

block:
  let ctx = newContext(Request(), Response(), GlobalScope())
  doAssert not ctx.handled
  doAssert ctx.size == 0
  doAssert ctx.first

  doAssertRaises(AbortError):
    abortExit(ctx)
