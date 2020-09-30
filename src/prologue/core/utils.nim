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


import strutils, os


template since*(version, body: untyped) {.dirty.} =
  ## limitation: can't be used to annotate a template (eg typetraits.get), would
  ## error: cannot attach a custom pragma.
  when (NimMajor, NimMinor) >= version:
    body

template sinceAPI*(version, body: untyped) {.dirty.} =
  ## limitation: can't be used to annotate a template (eg typetraits.get), would
  ## error: cannot attach a custom pragma.
  when (NimMajor, NimMinor) >= version:
    body

template beforeAPI*(version, body: untyped) {.dirty.} =
  ## limitation: can't be used to annotate a template (eg typetraits.get), would
  ## error: cannot attach a custom pragma.
  when (NimMajor, NimMinor) <= version:
    body

proc isStaticFile*(
  path: string, 
  dirs: openArray[string]
): tuple[hasValue: bool, filename, dir: string] {.inline.} =
  result = (false, "", "")
  var path = path.strip(chars = {'/'}, trailing = false)
  normalizePath(path)
  if not fileExists(path):
    return
  let file = splitFile(path)

  for dir in dirs:
    if dir.len == 0:
      continue
    if file.dir.startsWith(dir):
      return (true, file.name & file.ext, file.dir)
