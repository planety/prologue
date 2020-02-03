import os, tables, strutils, parsecfg, streams

import constants


export Config, loadConfig, writeConfig, setSectionKey


type
  Env* = object
    data*: OrderedTableRef[string, string]
  EnvError* = object of RootObj
  EnvWrongFormatError* = object of EnvError 


proc initEnv*(): Env =
  Env(data: newOrderedTable[string, string]())

# please set env with prefix namely PROLOGUE
proc putPrologueEnv*(key, val: string, prefix: string) {.inline.} =
  putEnv(prefix & key, val)

proc getPrologueEnv*(key: string, prefix: string, default = ""): string {.inline.} =
  getEnv(prefix & key, default)

proc getAllPrologueEnv*(prefix: string): OrderedTableRef[string, string] {.inline.} =
  result = newOrderedTable[string, string]()
  for k, v in envPairs():
    if k.startsWith(prefix):
      result[k] = v

proc existsPrologueEnv*(key: string, prefix: string): bool {.inline.} =
  existsEnv(prefix & key)

proc delPrologueEnv*(key: string, prefix: string) {.inline.} =
  delEnv(prefix & key)

proc loadPrologueEnv*(fileName: string): OrderedTableRef =
  result = newOrderedTable[string, string]()
  var f = newFileStream(fileName, fmRead)
  defer: f.close()
  if f != nil:
    var p: CfgParser
    open(p, f, fileName)
    defer: 
      p.close()
    while true:
      var e = p.next
      case e.kind:
        of cfgEof:
          break
        of cfgKeyValuePair:
          result[e.key] = e.value
        else:
          raise newException(EnvWrongFormatError, ".env file only support key-value pair")
    
          
proc setPrologueEnv*(env: Env, key, value: string) =
  env.data[key] = value

proc writePrologueEnv*(fileName: string, env: Env) =
  var f = newFileStream(fileName, fmWrite)
  defer: f.close()
  if f != nil:
    for key, value in env.data:
      f.writeLine(key & "=" & value)


when isMainModule:
  let prefix = ProloguePrefix
  putPrologueEnv("debug", "true", prefix)
  putPrologueEnv("port", "8080", prefix)
  putPrologueEnv("appName", "Starlight", prefix)
  putPrologueEnv("staticDir", "static", prefix)


  for k, v in envPairs():
    echo k, "->", v

  let res = getAllPrologueEnv(prefix)

  assert(res == {"PROLOGUE_appName": "Starlight",
                "PROLOGUE_port": "8080", "PROLOGUE_staticDir": "static",
                "PROLOGUE_debug": "true"}.newOrderedTable,
          "got: " & $res)


  let config = newStringStream("""[Prologue]
debug=true
port=8080
appName=Starlight
staticDir=static
""")

  echo loadConfig(config)["Prologue"]
