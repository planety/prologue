import ../../../src/prologue/core/application


block:
  var app = newApp(newSettings())
  doAssertRaises(RouteError):
    discard newGroup(app, "")

  discard newGroup(app, "/")

  doAssertRaises(RouteError):
    discard newGroup(app, "//")

  doAssertRaises(RouteError):
    discard newGroup(app, "x")

  doAssertRaises(RouteError):
    discard newGroup(app, "hello")

  doAssertRaises(RouteError):
    discard newGroup(app, "/hello/")
