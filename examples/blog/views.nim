import db_sqlite, strformat

import ../../src/prologue

import templates / [loginPage, registerPage]


# /login
proc login*(ctx: Context) {.async.} =
  let db = open(ctx.request.settings.dbPath, "", "", "")
  if ctx.request.reqMethod == HttpPost:
    var
      error: string
      id: string
      encoded: string
    let
      userName = ctx.getPostParams("username")
      password = SecretKey(ctx.getPostParams("password"))
      row = db.getRow(sql"SELECT * FROM user WHERE username = ?", userName)

    if row.len == 0:
      error = "Incorrect username"
    elif row.len < 3:
      error = "Incorrect username"
    else:
      # TODO process IndexError
      id = row[0]
      encoded = row[2]

      if not pbkdf2_sha256verify(password, encoded):
        error = "Incorrect password"

    if error.len == 0:
      ctx.session.clear()
      ctx.session["userId"] = id
      resp loginPage(ctx)
    else:
      resp error
  else:
    resp htmlResponse(loginPage(ctx))


# /logout
proc logout*(ctx: Context) {.async.} =
  discard

# /register
proc register*(ctx: Context) {.async.} =
  let db = open(ctx.request.settings.dbPath, "", "", "")
  defer: db.close()
  if ctx.request.reqMethod == HttpPost:
    var error: string
    let
      userName = ctx.getPostParams("username")
      password = pbkdf2_sha256encode(SecretKey(ctx.getPostParams(
          "password")), "Prologue")
    if userName.len == 0:
      error = "userName required"
    elif password.len == 0:
      error = "password required"
    elif db.getValue(sql"SELECT id FROM user WHERE username = ?",
        userName).len != 0:
      error = fmt"username {userName} registered already"

    if error.len == 0:
      db.exec(sql"INSERT INTO user (username, password) VALUES (?, ?)",
          userName, password)
      resp redirect(urlFor(ctx, "login"), Http301)
    else:
      resp error
  else:
    resp htmlResponse(registerPage(ctx))

