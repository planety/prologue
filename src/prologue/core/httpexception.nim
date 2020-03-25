type
  HttpError* = object of ValueError
  AbortError* = object of HttpError
