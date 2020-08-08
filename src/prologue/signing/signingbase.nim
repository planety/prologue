type
  BadDataError* = object of CatchableError
  BadSignatureError* = object of BadDataError
  BadTimeSignatureError* = object of BadDataError
  SignatureExpiredError* = object of BadTimeSignatureError
