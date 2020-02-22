import db_sqlite

import ../../src/prologue


# /login
proc login*(ctx: Context) {.async.} =
  resp "login"


# /register
proc register*(ctx: Context) {.async.} =
  let db = open(ctx.request.settings.dbPath, "", "", "")

  case ctx.request.reqMethod
  of HttpPost:
    var error: string
    let
      userName = getPostParams("username")
      password = pbkdf2_sha256encode(SecretKey(getPostParams(
          "password")), "Prologue")
    if userName == "":
      error = "userName required"
    elif password == "":
      error = "password required"
    elif db.getValue(sql"SELECT id FROM user WHERE username = ?", userName) != "":
      error = "username registered already"

    if error == "":
      db.exec(sql"INSERT INTO user (username, password) VALUES (?, ?)",
          userName, password)
      resp redirect(urlFor(login), Http301)
    else:
      resp error
  of HttpGet:
    await staticFileResponse(ctx, "register.html", "static")
  else:
    discard
  db.close()
