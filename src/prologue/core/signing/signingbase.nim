type
  BadDataError* = object of Exception
  BadSignatureError* = object of BadDataError
  BadTimeSignatureError* = object of BadDataError
  SignatureExpiredError* = object of BadTimeSignatureError
