import ../../src/prologue
import db_sqlite, strformat, strutils
from sqlite3 import last_insert_rowid

import list

let 
  db = open("todo.db", "", "", "") # Warning: This file is created in the current directory
db.exec(sql"CREATE TABLE todo (id INTEGER PRIMARY KEY, task char(80) NOT NULL, status bool NOT NULL)")
db.exec(sql"""INSERT INTO todo (task,status) VALUES ("Nim lang",0)""")
db.exec(sql"""INSERT INTO todo (task,status) VALUES ("Starlight web framework",1)""")
db.exec(sql"""INSERT INTO todo (task,status) VALUES ("Let's start to study Prologue web framework",1)""")
db.exec(sql"""INSERT INTO todo (task,status) VALUES ("My favourite web framework",1)""")
db.close()

proc todoList*(ctx: Context) {.async.} =
  let db = open("todo.db", "", "", "")
  let rows = db.getAllRows(sql"""SELECT id, task FROM todo WHERE status LIKE "1"""")
  db.close()
  resp htmlResponse(makeList(rows=rows))

proc newItem*(ctx: Context) {.async.} =
  if getQueryParams("save") != "":
    let
      row = getQueryParams("task").strip
      db = open("todo.db", "", "", "")
    db.exec(sql"INSERT INTO todo (task,status) VALUES (?,?)", row, 1)
    let
      id = last_insert_rowid(db)
    db.close()
    resp htmlResponse(fmt"<p>The new task was inserted into the database, the ID is {id}</p>")
  else:
    resp htmlResponse(newList())

proc editItem*(ctx: Context) {.async.} =
  if getQueryParams("save") != "":
    let
      edit = getQueryParams("task").strip
      status = getQueryParams("status").strip
      id = getPathParams("id", "")
    var statusId = 0
    if status == "open":
        statusId = 1
    let db= open("todo.db", "", "", "")
    db.exec(sql"UPDATE todo SET task = ?, status = ? WHERE id LIKE ?", edit, statusId, id)
    db.close()
    resp htmlResponse(fmt"<p>The item number {id} was successfully updated</p>")
  else:
    let db= open("todo.db", "", "", "")
    let id = getPathParams("id", "")
    let data = db.getAllRows(sql"SELECT task FROM todo WHERE id LIKE ?", id)
    resp htmlResponse(editList(id.parseInt, data[0]))

proc showItem*(ctx: Context) {.async.} =
  let
    db = open("todo.db", "", "", "")
    item = getPathParams("item", "")
    rows = db.getAllRows(sql"SELECT task FROM todo WHERE id LIKE ?", item)
  db.close()
  if rows.len == 0:
      resp "This item number does not exist!"
  else:
      resp fmt"Task: {rows[0]}"
