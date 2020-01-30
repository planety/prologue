import os, json


let 
  descriptionJson = %* {
    "openapi": "3.0.2",
    "info": {
      "title": "Prologue API",
      "version": "0.1.0"
      }
    }

  description* = $descriptionJson

proc writeDocs*(description: string, fileName = "openapi.json", dirs = "docs") =
  if not existsDir(dirs):
    createDir(dirs)
  let f = open(dirs / fileName, fmWrite)
  defer: f.close()
  f.write(description)

