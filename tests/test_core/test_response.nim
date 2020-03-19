from ../../src/prologue/core/response import initResponse, setHeader, addHeader, setCookie


import unittest, httpcore, strutils


suite "Test Response":
  let
    version = HttpVer11
    code = Http200
    body = "<h1>Hello, Prologue!</h1>"

  test "can init response":
    let
      response = initResponse(version, code, body = body)
    check:
      response.httpVersion == version
      response.code == code
      response.headers["Content-Type"] == "text/html; charset=UTF-8"
      response.body == body

  test "can set response header":
    var
      response = initResponse(version, code, body = body)

    response.setHeader("Content-Type", "text/plain")
    check:
      response.headers["content-type"] == "text/plain"

  test "can add response header":
    var
      response = initResponse(version, code, body = body)

    response.addHeader("Content-Type", "text/plain")
    check:
      seq[string](response.headers["CONTENT-TYPE"]) == @[
          "text/html; charset=UTF-8", "text/plain"]

  test "can set response cookie":
    var
      response = initResponse(version, code, body = body)

    response.setCookie("username", "flywind")
    response.setCookie("password", "root")
    check:
      seq[string](response.headers["set-cookie"]).join("; ") ==
          "username=flywind; SameSite=Lax; password=root; SameSite=Lax"

