import prologue

include "csrf.nimf"

proc hello*(ctx: Context) {.async.} =
  resp alignForm(csrfToken(ctx))
