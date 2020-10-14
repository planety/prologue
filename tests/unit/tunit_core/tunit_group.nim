import ../../../src/prologue/core/application
import ../../../src/prologue/middlewares/middlewares


block:
  var app = newApp()
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

block:
  var app = newApp()
  var base = newGroup(app, "/apiv2", @[debugRequestMiddleware()])
  var level1 = newGroup(app,"/level1", @[debugRequestMiddleware(), debugRequestMiddleware()], base)
  var level2 = newGroup(app, "/level2", @[debugRequestMiddleware()], level1)
  var level3 = newGroup(app, "/level3", @[debugRequestMiddleware()], level2)

  block:
    let (r, m) = getAllInfos(base, "/home", @[debugRequestMiddleware()])
    doAssert r == "/apiv2/home"
    doAssert m.len == 2

  block:
    let (r, m) = getAllInfos(level1, "/home", @[debugRequestMiddleware()])
    doAssert r == "/apiv2/level1/home"
    doAssert m.len == 4
  
  block:
    let (r, m) = getAllInfos(level2, "/home", @[debugRequestMiddleware()])
    doAssert r == "/apiv2/level1/level2/home"
    doAssert m.len == 5

  block:
    let (r, m) = getAllInfos(level3, "/home", @[debugRequestMiddleware()])
    doAssert r == "/apiv2/level1/level2/level3/home"
    doAssert m.len == 6
