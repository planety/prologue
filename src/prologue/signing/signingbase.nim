import base64, strutils

type
  BadDataError* = object of Exception
  BadSignatureError* = object of BadDataError
  BadTimeSignatureError* = object of BadDataError
  SignatureExpiredError* = object of BadTimeSignatureError

proc urlsafeBase64Encode*[T: SomeInteger | char](s: openArray[T]): string {.inline.} =
  ## URL-safe and Cookie-safe encoding
  s.encode.replace('+', '-').replace('/', '_')

proc urlsafeBase64Encode*(s: string): string {.inline.} =
  ## URL-safe and Cookie-safe encoding
  s.encode.replace('+', '-').replace('/', '_')

proc urlsafeBase64Decode*(s: string): string {.inline.} =
  ## URL-safe and Cookie-safe decoding
  s.replace('-', '+').replace('_', '/').decode
