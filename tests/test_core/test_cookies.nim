from ../../src/prologue/core/cookies import parseCookies, secondsForward,
    daysForward, timesForward, setCookie


import unittest, strtabs, options, strutils


suite "Test Cookies":
  test "can parse cookies with one element":
    let tabs = parseCookies("username=flywind ")
    check:
      tabs["username"] == "flywind "

  test "can parse cookies with two elements":
    let tabs = parseCookies("username=flywind; password=root")
    check:
      tabs["username"] == "flywind"
      tabs["password"] == "root"

  test "can parse empty cookies":
    let tabs = parseCookies("")
    check $tabs == $newStringTable()

  test "timesForward can work":
    discard secondsForward(0)
    discard daysForward(10)
    discard timesForward(1, 2, 3, 4, 5, 6, 7, 8)

    # setCookie*(key, value: string, expires = "", maxAge: Option[int] = none(int), domain = "", path = "",
    # secure = false, httpOnly = false, sameSite = Lax)
  test "can set cookies":
    check:
      setCookie("username", "flywind") == "username=flywind; SameSite=Lax"
      setCookie("password", "root", maxAge = some(120)).startsWith("password=root; Max-Age=")
