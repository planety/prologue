import os, strtabs, strutils

import constants


# please set env with prefix namely PROLOGUE
proc putPrologueEnv*(key, val: string, prefix: string) {.inline.} =
  putEnv(prefix & key, val)

proc getPrologueEnv*(key: string, prefix: string, default = ""): string {.inline.} =
  getEnv(prefix & key, default)

proc getAllPrologueEnv*(prefix: string): StringTableRef {.inline.} =
  result = newStringTable()
  for k, v in envPairs():
    if k.startsWith(prefix):
      result[k] = v

proc existsPrologueEnv*(key: string, prefix: string): bool {.inline.} =
  existsEnv(prefix & key)

proc delPrologueEnv*(key: string, prefix: string) {.inline.} =
  delEnv(prefix & key)


when isMainModule:
  let prefix = ProloguePrefix
  putPrologueEnv("debug", "true", prefix)
  putPrologueEnv("port", "8080", prefix)
  putPrologueEnv("appName", "Starlight", prefix)
  putPrologueEnv("staticDir", "static", prefix)


  for k, v in envPairs():
    echo k, "->", v

  let res = getAllPrologueEnv(prefix)

  assert($res == ${"PROLOGUE_appName": "Starlight",
                "PROLOGUE_port": "8080", "PROLOGUE_staticDir": "static",
                "PROLOGUE_debug": "true"}.newStringTable,
          "got: " & $res)
