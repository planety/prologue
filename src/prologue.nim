import prologue/core/application
import prologue/dsl/route_dsl
export route_dsl
export application


when isMainModule:
  from prologue/command/init import main
  main()
