type
  BadDataError* = object of ValueError
  BadSignatureError* = object of BadDataError
  BadTimeSignatureError* = object of BadDataError
  SignatureExpiredError* = object of BadTimeSignatureError
