import std/sequtils

import ./context
import ./server
import ./httpexception


type
  Group* = ref object   ## Grouping object
    app*: Prologue
    parent {.cursor.}: Group
    route: string
    middlewares: seq[HandlerAsync]


func newGroup*(app: Prologue, route: string, middlewares: openArray[HandlerAsync] = @[], 
               parent: Group = nil): Group =
  ## Creates a new `Group`.
  if route.len == 0:
    raise newException(RouteError, "Route can't be empty, at least use `/`!")

  if route[0] != '/':
    raise newException(RouteError, "Route must start with `/`!")

  if route.len > 1:
    if route[^1] == '/':
      raise newException(RouteError, "Route can't end with `/` except root directory!")

  Group(app: app, route: route, middlewares: @middlewares, parent: parent)

func getAllInfos*(group: Group, route: string, middlewares: openArray[HandlerAsync]): (string, seq[HandlerAsync]) =
  ## Retrieves group infos regarding middlewares and route.
  var parent = group
  while parent != nil:
    if parent.route.len != 1:
      result[0].insert parent.route
    result[1].insert parent.middlewares
    parent = parent.parent

  result[0].add route
  result[1].add middlewares
