import prologue/core/application

export application


when isMainModule:
  from prologue/command/init import main
  main()
