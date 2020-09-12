import db_sqlite, strformat

import ../../src/prologue
import ../../src/prologue/security/hasher

import templates / [loginPage, registerPage]

import consts

# /login
proc login*(ctx: Context) {.async.} =
  let db = open(consts.dbPath, "", "", "")
  if ctx.request.reqMethod == HttpPost:
    var
      error: string
      id: string
      encoded: string
    let
      username = ctx.getPostParams("username")
      password = SecretKey(ctx.getPostParams("password"))
      row = db.getRow(sql"SELECT * FROM user WHERE username = ?", username)

    if row.len == 0:
      error = "Incorrect username"
    elif row.len < 3:
      error = "Incorrect username"
    else:
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
  echo ctx.session
  echo "123456789"

# /register
proc register*(ctx: Context) {.async.} =
  let db = open(consts.dbPath, "", "", "")
  if ctx.request.reqMethod == HttpPost:
    var error: string
    let
      username = ctx.getPostParams("username")
      password = pbkdf2_sha256encode(SecretKey(ctx.getPostParams(
          "password")), "Prologue")
    if username.len == 0:
      error = "username required"
    elif password.len == 0:
      error = "password required"
    elif db.getValue(sql"SELECT id FROM user WHERE username = ?",
        username).len != 0:
      error = fmt"username {username} registered already"

    if error.len == 0:
      db.exec(sql"INSERT INTO user (username, password) VALUES (?, ?)",
          username, password)
      resp redirect(urlFor(ctx, "login"), Http301)
    else:
      resp error
  else:
    resp htmlResponse(registerPage(ctx))

  db.close()
