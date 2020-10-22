import std/[db_sqlite, strformat]

import prologue
import prologue/security/hasher

import ./consts

import
  templates/login,
  templates/register,
  templates/editpost,
  templates/index


# /login
proc login*(ctx: Context) {.async.} =
  let db = open(consts.dbPath, "", "", "")
  if ctx.request.reqMethod == HttpPost:
    var
      error: string
      id: string
      fullname: string
      encoded: string
    let
      username = ctx.getPostParams("username")
      password = SecretKey(ctx.getPostParams("password"))
      row = db.getRow(sql"SELECT * FROM users WHERE username = ?", username)

    if row.len == 0:
      error = "Incorrect username"
    elif row.len < 3:
      error = "Incorrect username"
    else:
      id = row[0]
      fullname = row[1]
      encoded = row[3]

      if not pbkdf2_sha256verify(password, encoded):
        error = "Incorrect password"

    if error.len == 0:
      ctx.session.clear()
      ctx.session["userId"] = id
      ctx.session["userFullname"] = fullname
      resp redirect(urlFor(ctx, "index"), Http302)
    else:
      resp htmlResponse(loginPage(ctx, "Login", error))
  else:
    resp htmlResponse(loginPage(ctx, "Login"))

  db.close()

# /logout
proc logout*(ctx: Context) {.async.} =
  ctx.session.clear()
  resp redirect(urlFor(ctx, "index"), Http302)

# /register
proc register*(ctx: Context) {.async.} =
  let db = open(consts.dbPath, "", "", "")
  if ctx.request.reqMethod == HttpPost:
    var error: string
    let
      username = ctx.getPostParams("username")
      password = pbkdf2_sha256encode(SecretKey(ctx.getPostParams(
              "password")), "Prologue")
    var fullname = ctx.getPostParams("fullname")

    if username.len == 0:
      error = "username required"
    elif password.len == 0:
      error = "password required"
    elif db.getValue(sql"SELECT id FROM users WHERE username = ?",
            username).len != 0:
      error = fmt"Username {username} registered already"

    if error.len == 0:
      if fullname.len == 0: fullname = username
      db.exec(sql"INSERT INTO users (fullname, username, password) VALUES (?, ?, ?)",
              fullname, username, password)
      resp redirect(urlFor(ctx, "login"), Http301)
    else:
      resp htmlResponse(registerPage(ctx, "Register", error))
  else:
    resp htmlResponse(registerPage(ctx, "Register"))

  db.close()

# /
proc read*(ctx: Context) {.async.} =
  let db = open(consts.dbPath, "", "", "")
  var posts: seq[seq[string]] = @[]
  for x in db.fastRows(sql"SELECT * FROM posts"):
    posts.add(x)

  db.close()
  resp htmlResponse(indexPage(ctx, "List of posts", posts))

# /create
proc create*(ctx: Context) {.async.} =
  if ctx.session.getOrDefault("userId").len != 0:
    if ctx.request.reqMethod == HttpPost:
      let
        db = open(consts.dbPath, "", "", "")
        title = ctx.getPostParams("title")
        content = ctx.getPostParams("content")

      db.exec(sql"INSERT INTO posts (author_id, title, body) VALUES (?, ?, ?)",
              ctx.session["userId"], title, content)
      resp redirect(urlFor(ctx, "index"), Http302)
    else:
      resp htmlResponse(editPage(ctx, "Create"))

# /update
proc update*(ctx: Context) {.async.} =
  if ctx.session.getOrDefault("userId").len != 0:
    let
      db = open(consts.dbPath, "", "", "")
      post = db.getRow(sql"SELECT * FROM posts WHERE id = ?", ctx.getPathParams("id"))

    if ctx.request.reqMethod == HttpPost:
      # we may add some validation for empty fields here but input fields are already marked as 'required'
      let
        id = ctx.getPostParams("id")
        title = ctx.getPostParams("title")
        content = ctx.getPostParams("content")
      db.exec(sql"UPDATE posts SET title = ?, body = ? WHERE id = ?", title,
          content, id)
      resp redirect(urlFor(ctx, "index"), Http302)
    else:
      resp htmlResponse(editPage(ctx, "Update", post))
    # can we close connection after 'resp' was called?
    db.close()

# /delete
proc delete*(ctx: Context) {.async.} =
  if ctx.session.getOrDefault("userId").len != 0:
    let
      id = ctx.getPathParams("id")
      db = open(consts.dbPath, "", "", "")

    db.exec(sql"DELETE FROM posts WHERE id = ?", id)
    db.close()
    resp redirect(urlFor(ctx, "index"), Http302)
