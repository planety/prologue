import asyncdispatch


# when compiles(getGlobalDispatcher().handles):
#   when defined(usestd):
#     import naive/request
#   else:
#     import beast/request
# else:
when defined(windows) or defined(usestd):
  import naive/request
else:
  import beast/request

export request
