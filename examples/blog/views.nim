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
      userName = getPostParams("username")
      password = SecretKey(getPostParams("password"))
      row = db.getRow(sql"SELECT * FROM user WHERE username = ?", userName)
      
    echo row
    if row == @[]:
      error = "Incorrect username"
    elif row.len < 3:
      error = "Incorrect username"
    else:
      # TODO process IndexError
      id = row[0]
      encoded = row[2]
      
      if not pbkdf2_sha256verify(password, encoded):
        error = "Incorrect password"

    if error == "":
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
      userName = getPostParams("username")
      password = pbkdf2_sha256encode(SecretKey(getPostParams(
          "password")), "Prologue")
    if userName == "":
      error = "userName required"
    elif password == "":
      error = "password required"
    elif db.getValue(sql"SELECT id FROM user WHERE username = ?", userName) != "":
      error = fmt"username {userName} registered already"

    if error == "":
      db.exec(sql"INSERT INTO user (username, password) VALUES (?, ?)",
          userName, password)
      resp redirect(urlFor(login), Http301)
    else:
      resp error
  else:
    resp htmlResponse(registerPage(ctx))

