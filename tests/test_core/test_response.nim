import ../../src/prologue/core/response


import unittest, httpcore, strutils


suite "Test Response":
  let
    version = HttpVer11
    status = Http200
    body = "<h1>Hello, Prologue!</h1>"

  test "can init response":
    let
      response = initResponse(version, status, body = body)
    check:
      response.httpVersion == version
      response.status == status
      response.httpHeaders["Content-Type"] == "text/html; charset=UTF-8"
      response.body == body

  test "can set response header":
    var
      response = initResponse(version, status, body = body)

    response.setHeader("Content-Type", "text/plain")
    check:
      response.httpHeaders["content-type"] == "text/plain"

  test "can add response header":
    var
      response = initResponse(version, status, body = body)

    response.addHeader("Content-Type", "text/plain")
    check:
      seq[string](response.httpHeaders["CONTENT-TYPE"]) == @[
          "text/html; charset=UTF-8", "text/plain"]

  test "can set response cookie":
    var
      response = initResponse(version, status, body = body)

    response.setCookie("username", "flywind")
    response.setCookie("password", "root")
    check:
      seq[string](response.httpHeaders["set-cookie"]).join("; ") == 
          "username=flywind; SameSite=Lax; password=root; SameSite=Lax"

