import base
import ../../../src/prologue


proc loginPage*(ctx: Context): string =
  basePage(ctx, name, "Log In", "Login")
