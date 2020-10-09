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
  Group(app: app, route: route, middlewares: @middlewares, parent: parent)

proc getAllInfos*(group: Group, route: string, middlewares: openArray[HandlerAsync]): (string, seq[HandlerAsync]) =
  var parent = group
  while parent != nil:
    parent = group.parent
    result[0].add parent.route
    result[1].add parent.middlewares
