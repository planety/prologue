# Copyright 2020 Zeshen Xing
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


## This module contains basic operating system facilities like
## retrieving environment variables, reading command line arguments,
## working with directories, running shell commands, etc.
##
## .. code-block::
##   import os
##
##   let myFile = "/path/to/my/file.nim"
##
##   let pathSplit = splitPath(myFile)
##   assert pathSplit.head == "/path/to/my"
##   assert pathSplit.tail == "file.nim"
##
##   assert parentDir(myFile) == "/path/to/my"
##
##   let fileSplit = splitFile(myFile)
##   assert fileSplit.dir == "/path/to/my"
##   assert fileSplit.name == "file"
##   assert fileSplit.ext == ".nim"
##
##   assert myFile.changeFileExt("c") == "/path/to/my/file.c"


import os, tables, strutils, parsecfg, streams

import ./types


export Config, loadConfig, writeConfig, setSectionKey, types


type
  Env* = object
    data: OrderedTableRef[string, string]
  EnvError* = object of CatchableError
  EnvWrongFormatError* = object of EnvError


proc initEnv*(): Env =
  Env(data: newOrderedTable[string, string]())

proc `$`*(env: Env): string =
  $env.data

proc `[]`*(env: Env, key: string): string =
  env.data[key]

proc hasKey*(env: Env, key: string): bool =
  if key in env.data:
    result = true
  else:
    result = false

proc contains*(env: Env, key: string): bool =
  if key in env.data:
    result = true
  else:
    result = false

proc get*(env: Env, key: string): string {.inline.} =
  result = env.data[key]

proc getOrDefault*[T: BaseType](env: Env, key: sink string, default: T): T {.inline.} =
  if key notin env.data:
    return default
  parseValue(env.data[key], default)

iterator keys*(env: Env): string =
  for key in env.data.keys:
    yield key

iterator values*(env: Env): string =
  for value in env.data.values:
    yield value

iterator pairs*(env: Env): (string, string) =
  for pair in env.data.pairs:
    yield pair

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

proc loadPrologueEnv*(filename: string): Env =
  result = initEnv()
  var f = newFileStream(filename, fmRead)

  if f != nil:
    var p: CfgParser
    open(p, f, filename)
    # TODO buggy in --gc:arc
    defer:
      p.close()
      f.close()
    while true:
      var e = p.next
      case e.kind
      of cfgEof:
        break
      of cfgKeyValuePair:
        result.data[e.key] = e.value
      else:
        raise newException(EnvWrongFormatError, ".env file only support key-value pair")

proc setPrologueEnv*(env: Env, key, value: string) =
  env.data[key] = value

proc writePrologueEnv*(filename: string, env: Env) =
  var f = newFileStream(filename, fmWrite)
  if f != nil:
    for key, value in env.data:
      f.writeLine(key & "=" & value)
    f.close()


when isMainModule:
  import ./constants


  let prefix = ProloguePrefix
  # only work in application scope
  putPrologueEnv("debug", "true", prefix)
  putPrologueEnv("port", "8080", prefix)
  putPrologueEnv("appName", "Starlight", prefix)
  putPrologueEnv("staticDir", "static", prefix)


  for k, v in envPairs():
    echo k, "->", v

  let res = getAllPrologueEnv(prefix)

  assert(res.len == 4, "got: " & $res)

  let config = newStringStream("""[Prologue]
debug=true
port=8080
appName=Starlight
staticDir=static
""")

  echo loadConfig(config)["Prologue"]
