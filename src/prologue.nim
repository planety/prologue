import prologue/core/application
import prologue/core/route_dsl
export application
export route_dsl


when isMainModule:
  from prologue/command/init import main
  main()
