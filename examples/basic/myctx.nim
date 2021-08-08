import prologue

type
  DataContext* = ref object of Context
    id*: int

method extend*(ctx: DataContext) =
  ctx.id = 999