type
  HttpError* = object of CatchableError
  AbortError* = object of HttpError
