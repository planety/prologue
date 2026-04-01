## Async backend switch for Prologue.
##
## Use kairos (chronos) via nimble feature:
##   nimble install prologue[kairos]
##
## Or manually:
##   nim c -d:features.prologue.kairos myapp.nim
##   nim c -d:asyncBackend=chronos myapp.nim
##
## Default is asyncdispatch + httpx.

const asyncBackend {.strdefine.} = ""
const useKairos* = asyncBackend == "chronos" or defined(features.prologue.kairos)

when useKairos:
  import chronos except `$`, tables, `==`, OrderedTable, OrderedTableRef,
    initOrderedTable, `[]`, `[]=`, contains, del, len, hasKey, pairs, keys
  export chronos except `$`, tables, `==`, OrderedTable, OrderedTableRef,
    initOrderedTable, `[]`, `[]=`, contains, del, len, hasKey, pairs, keys


else:
  import std/asyncdispatch
  export asyncdispatch

  import pkg/httpx except Settings, Request
  export httpx except Settings, Request
