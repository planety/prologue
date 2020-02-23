import base
import ../../../src/prologue


proc registerPage*(ctx: Context): string =
  basePage(ctx, name, "Register", formPage("Register", "Register"))
