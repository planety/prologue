import parseopt 


proc main*() =
  var 
    op = initOptParser()

  while true:
    op.next()
    case op.kind
    of {cmdLongOption, cmdShortOption}:
      case op.key
      of "help", "h":
        stdout.write("This is help.")
      else: 
        discard
    of cmdArgument: 
      discard
    of cmdEnd: 
      break
