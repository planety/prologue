import std/[db_sqlite, os, strutils, logging]

import ./consts


proc initDb*() =
  if not fileExists(consts.dbPath):
    let
      db = open(consts.dbPath, "", "", "")
      schema = readFile(schemaPath)
    for line in schema.split(";"):
      if line == "\c\n" or line == "\n":
        continue
      db.exec(sql(line.strip))
    db.close()
    logging.info("Initialized the database.")
