import prologue
import std/[db_sqlite, strformat, strutils]
from std/sqlite3 import last_insert_rowid

import ./templates/basic

let
  db = open("todo.db", "", "", "") # Warning: This file is created in the current directory

if not db.tryExec(sql"select count(*) from todo"):
  db.exec(sql"CREATE TABLE todo (id INTEGER PRIMARY KEY, task char(80) NOT NULL, status bool NOT NULL)")
  db.exec(sql"""INSERT INTO todo (task,status) VALUES ("Nim lang",0)""")
  db.exec(sql"""INSERT INTO todo (task,status) VALUES ("Prologue web framework",1)""")
  db.exec(sql"""INSERT INTO todo (task,status) VALUES ("Let's start to study Prologue web framework",1)""")
  db.exec(sql"""INSERT INTO todo (task,status) VALUES ("My favourite web framework",1)""")
db.close()

proc todoList*(ctx: Context) {.async.} =
  let db = open("todo.db", "", "", "")
  let rows = db.getAllRows(sql("""SELECT id, task FROM todo WHERE status LIKE "1""""))
  db.close()
  resp htmlResponse(makeList(rows=rows))

proc newItem*(ctx: Context) {.async.} =
  if ctx.getQueryParams("save").len != 0:
    let
      row = ctx.getQueryParams("task").strip
      db = open("todo.db", "", "", "")
    db.exec(sql"INSERT INTO todo (task,status) VALUES (?,?)", row, 1)
    let
      id = last_insert_rowid(db)
    db.close()
    resp htmlResponse(fmt"<p>The new task was inserted into the database, the ID is {id}</p><a href=/>Back to list</a>")
  else:
    resp htmlResponse(newList())

proc editItem*(ctx: Context) {.async.} =
  if ctx.getQueryParams("save").len != 0:
    let
      edit = ctx.getQueryParams("task").strip
      status = ctx.getQueryParams("status").strip
      id = ctx.getPathParams("id", "")
    var statusId = 0
    if status == "open":
        statusId = 1
    let db= open("todo.db", "", "", "")
    db.exec(sql"UPDATE todo SET task = ?, status = ? WHERE id LIKE ?", edit, statusId, id)
    db.close()
    resp htmlResponse(fmt"<p>The item number {id} was successfully updated</p><a href=/>Back to list</a>")
  else:
    let db= open("todo.db", "", "", "")
    let id = ctx.getPathParams("id", "")
    let data = db.getAllRows(sql"SELECT task FROM todo WHERE id LIKE ?", id)
    resp htmlResponse(editList(id.parseInt, data[0]))

proc showItem*(ctx: Context) {.async.} =
  let
    db = open("todo.db", "", "", "")
    item = ctx.getPathParams("item", "")
    rows = db.getAllRows(sql"SELECT task, status FROM todo WHERE id LIKE ?", item)
  db.close()
  let home_link = """<a href="/">Back to list</a>"""
  if rows.len == 0:
    resp "This item number does not exist!" & home_link
  else:
    let
      task = rows[0][0]
      status = block:
        if rows[0][1] == "1":
          "Done"
        else:
          "Doing"
    resp fmt"Task: {task}<br/>Status: {status}</br>" & home_link
