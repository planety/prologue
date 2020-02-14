type
  BadData* = object of Exception
  BadSignature* = object of BadData
  BadTimeSignature* = object of BadData
  SignatureExpired* = object of BadTimeSignature