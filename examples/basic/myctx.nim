import prologue

type
  DataContext* = ref object of Context
    id*: int

method extend*(ctx: DataContext) {.gcsafe.} =
  ctx.id = 999