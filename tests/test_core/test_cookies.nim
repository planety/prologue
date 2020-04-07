from ../../src/prologue/core/cookies import parseCookie, secondsForward,
    daysForward, timesForward, setCookie

from ../../src/prologue/core/types import Strict


import unittest, strtabs, options, strutils, strformat, times


suite "Test Cookies":
  test "can parse cookie with one element":
    let tabs = parseCookie("username=flywind ")
    check:
      tabs["username"] == "flywind "

  test "can parse cookie with two elements":
    let tabs = parseCookie("username=flywind; password=root")
    check:
      tabs["username"] == "flywind"
      tabs["password"] == "root"

  test "can parse empty cookies":
    let tabs = parseCookie("")
    check $tabs == $newStringTable(mode = modeCaseSensitive)

  test "timesForward can work":
    discard secondsForward(0)
    discard daysForward(10)
    discard timesForward(1, 2, 3, 4, 5, 6, 7, 8)

  test "can set cookies":
    check:
      setCookie("username", "flywind") == "username=flywind; SameSite=Lax"
      setCookie("password", "root", maxAge = some(120)).startsWith("password=root; Max-Age=")


suite "Test Set Cookie":
  let
    username = "admin"
    password = "root"

  test "Key-Value":
    let cookie = setCookie(username, password)
    check cookie == fmt"{username}={password}; SameSite=Lax"

  test "Max-Age":
    let 
      maxAge = 10
      cookie = setCookie(username, password, maxAge = some(maxAge))
    check cookie == fmt"{username}={password}; Max-Age={maxAge}; SameSite=Lax"

  test "Secure":
    let 
      secure = true
      cookie = setCookie(username, password, secure = secure)
    check cookie == fmt"{username}={password}; Secure; SameSite=Lax"

  test "Http-Only":
    let 
      httpOnly = true
      cookie = setCookie(username, password, httpOnly = httpOnly)
    check cookie == fmt"{username}={password}; HttpOnly; SameSite=Lax"

  test "Domain":
    let 
      domain = "www.netkit.com"
      cookie = setCookie(username, password, domain = domain)
    check cookie == fmt"{username}={password}; Domain={domain}; SameSite=Lax"
    check setCookie(username, password, domain = "   ") == fmt"{username}={password}; SameSite=Lax"
    
  test "path":
    let 
      path = "/index"
      cookie = setCookie(username, password, path = path)
    check cookie == fmt"{username}={password}; Path={path}; SameSite=Lax"
    check setCookie(username, password, path = "   ") == fmt"{username}={password}; SameSite=Lax"

  test "expires String":
    let
      expires = "Mon, 6 Apr 2020 12:55:00 GMT"
      cookie = setCookie(username, password, expires)
    check cookie == fmt"{username}={password}; Expires={expires}; SameSite=Lax"

  test "expires DateTime":
    let 
      dt = initDateTime(6, mApr, 2020, 13, 3, 0, 0, utc())
      expires = format(dt, "ddd',' dd MMM yyyy HH:mm:ss 'GMT'")
      cookie = setCookie(username, password, expires)
    check cookie == fmt"{username}={password}; Expires={expires}; SameSite=Lax"
    check setCookie(username, password, expires = "   ") == fmt"{username}={password}; SameSite=Lax"

  test "sameSite":
    let 
      sameSite = Strict 
      cookie = setCookie(username, password, sameSite = sameSite)
    check cookie == fmt"{username}={password}; SameSite={sameSite}"
