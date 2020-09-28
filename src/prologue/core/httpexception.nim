type
  PrologueError* = object of CatchableError

  HttpError* = object of PrologueError
  AbortError* = object of HttpError

  RouteError* = object of PrologueError
  RouteResetError* = object of RouteError
  DuplicatedRouteError* = object of RouteError
  DuplicatedReversedRouteError* = object of RouteError
