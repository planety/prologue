import db_sqlite, os, strutils, logging


const
  dbPath = "blog.db"
  schemaPath = "schema.sql"


if not existsFile(dbPath):
  let
    db = open(dbPath, "", "", "")
    schema = readFile(schemaPath)
  for line in schema.split(";"):
    if line == "\c\n":
      continue
    db.exec(sql(line.strip))
  db.close()
  logging.info("Initialized the database.")
