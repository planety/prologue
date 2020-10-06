import ../../../src/prologue/core/httpexception


block:
  doAssert HttpError is PrologueError
  doAssert AbortError is PrologueError
  doAssert RouteError is PrologueError
  doAssert RouteResetError is PrologueError
  doAssert DuplicatedRouteError is PrologueError
  doAssert DuplicatedReversedRouteError is PrologueError
