import base64, strutils

type
  BadData* = object of Exception
  BadSignature* = object of BadData
  BadTimeSignature* = object of BadData
  SignatureExpired* = object of BadTimeSignature

proc urlsafeBase64Encode*[T: SomeInteger | char](s: openArray[T]): string {.inline.} =
  ## URL-safe and Cookie-safe encoding
  s.encode.replace('+', '-').replace('/', '_')

proc urlsafeBase64Encode*(s: string): string {.inline.} =
  ## URL-safe and Cookie-safe encoding
  s.encode.replace('+', '-').replace('/', '_')

proc urlsafeBase64Decode*(s: string): string {.inline.} =
  ## URL-safe and Cookie-safe decoding
  s.replace('-', '+').replace('_', '/').decode
