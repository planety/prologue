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


## This module contains basic configure facilities like
## retrieving, setting environment variables and so on.

runnableExamples:
  import os, tables, streams


  let prefix = "PROLOGUE_"
  # only work in application scope
  delEnv("PROLOGUE")
  putPrologueEnv("debug", "true", prefix)
  putPrologueEnv("port", "8080", prefix)
  putPrologueEnv("appName", "Prologue", prefix)
  putPrologueEnv("staticDir", "static", prefix)


  discard getAllPrologueEnv(prefix)


  let config = newStringStream("""[Prologue]
debug=true
port=8080
appName=Prologue
staticDir=static
""")

  let tab = loadConfig(config)["Prologue"]
  doAssert tab["appName"] == "Prologue"
  doAssert tab["staticDir"] == "static"
  doAssert tab["debug"] == "true"
  doAssert tab["port"] == "8080"


import std/[os, tables, strutils, parsecfg, streams]

import ./types, ./constants

export Config, loadConfig, writeConfig, setSectionKey, types


type
  Env* = object
    data: OrderedTableRef[string, string]
  EnvError* = object of CatchableError
  EnvWrongFormatError* = object of EnvError

  ConfigFileExt* = enum
    Json = "json"
    Toml = "toml"
    Yaml = "yaml"


func initEnv*(): Env {.inline.} =
  ## Initializes an `Env`.
  Env(data: newOrderedTable[string, string]())

func `$`*(env: Env): string {.inline.} =
  ## Gets the string form of `Env`.
  $env.data

func `[]`*(env: Env, key: string): string {.inline.} =
  ## Retrieves a value of key in `Env`.
  env.data[key]

func hasKey*(env: Env, key: string): bool {.inline.} =
  ## Returns true if `key` exists in `Env`.
  if key in env.data:
    result = true
  else:
    result = false

func contains*(env: Env, key: string): bool {.inline.} =
  ## Returns true if `key` exists in `Env`.
  if key in env.data:
    result = true
  else:
    result = false

func get*(env: Env, key: string): string {.inline.} =
  ## Retrieves a value of `key` in `Env`.
  result = env.data[key]

func getOrDefault*[T: BaseType](env: Env, key: string, default: T): T {.inline.} =
  ## Retrieves a value of `key` if `key` exists in `Env`. Otherwise the default value
  ## will be returned.
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

proc getPrologueEnv*(): string =
  ## Gets `PROLOGUE` env variables.
  getEnv(ProloguePrefix, "")

# please set env with prefix namely PROLOGUE
proc putPrologueEnv*(key, val: string, prefix: string) {.inline.} =
  ## Puts (``key``, ``val``) pairs with ``prefix`` to environment variables.
  putEnv(prefix & "_" & key, val)

proc getPrologueEnv*(key: string, prefix: string, default = ""): string {.inline.} =
  ## Gets (``key``, ``val``) pairs with ``prefix`` from environment variables. If
  ## ``key`` can't be found, ``default`` will be returned.
  getEnv(prefix & "_" & key, default)

proc getAllPrologueEnv*(prefix: string): OrderedTableRef[string, string] {.inline.} =
  ## Gets all (``key``, ``val``) pairs with ``prefix`` from environment variables.
  result = newOrderedTable[string, string]()
  for k, v in envPairs():
    if k.startsWith(prefix):
      result[k] = v

proc existsPrologueEnv*(key: string, prefix: string): bool {.inline.} =
  existsEnv(prefix & "_" & key)

proc delPrologueEnv*(key: string, prefix: string) {.inline.} =
  delEnv(prefix & "_" & key)

proc loadPrologueEnv*(filename: string): Env =
  result = initEnv()
  var f = newFileStream(filename, fmRead)

  if f != nil:
    var p: CfgParser
    open(p, f, filename)
    while true:
      var e = p.next
      case e.kind
      of cfgEof:
        break
      of cfgKeyValuePair:
        result.data[e.key] = e.value
      else:
        raise newException(EnvWrongFormatError, ".env file only support key-value pair")
    f.close()
    p.close()

proc setPrologueEnv*(env: Env, key, value: string) {.inline.} =
  env.data[key] = value

proc writePrologueEnv*(filename: string, env: Env) =
  var f = newFileStream(filename, fmWrite)
  if f != nil:
    for key, value in env.data:
      f.writeLine(key & "=" & value)
    f.close()
