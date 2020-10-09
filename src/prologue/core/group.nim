import std/sequtils

import ./context
import ./server


type
  Group* = ref object
    app*: Prologue
    parent {.cursor.}: Group
    route: string
    middlewares: seq[HandlerAsync]

func newGroup*(app: Prologue, route: string, middlewares: openArray[HandlerAsync] = @[], 
               parent: Group = nil): Group =
  doAssert route.len > 0, "Route can't be empty, at least use `/`!"
  doAssert route[0] == '/', "Route must start with `/`!"
  doAssert route[^1] != '/', "Route can't end with `/` except root directory!"
  Group(app: app, route: route, middlewares: @middlewares, parent: parent)

func getAllInfos*(group: Group, route: string, middlewares: openArray[HandlerAsync]): (string, seq[HandlerAsync]) =
  var parent = group
  while parent != nil:
    parent = group.parent
    if parent.route.len != 1:
      result[0].insert parent.route
    result[1].insert parent.middlewares

  result[0].add route
  result[1].add middlewares
