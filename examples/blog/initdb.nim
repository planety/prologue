import db_sqlite, os, strutils

import configure


const
  schemaPath = "schema.sql"


if not existsFile(settings.dbPath):
  let
    db = open(settings.dbPath, "", "", "")
    schema = readFile(schemaPath)
  for line in schema.split(";"):
    if line == "\c\n":
      continue
    db.exec(sql(line.strip))
  db.close()
  echo("Initialized the database.")
