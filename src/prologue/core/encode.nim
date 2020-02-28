import base64, strutils


proc base64Encode*[T: SomeInteger | char](s: openArray[T]): string {.inline.} =
  s.encode

proc base64Encode*(s: string): string {.inline.} =
  s.encode

proc base64Decode*(s: string): string {.inline.} =
  s.decode

proc urlsafeBase64Encode*[T: SomeInteger | char](s: openArray[T]): string {.inline.} =
  ## URL-safe and Cookie-safe encoding
  s.encode.replace('+', '-').replace('/', '_')

proc urlsafeBase64Encode*(s: string): string {.inline.} =
  ## URL-safe and Cookie-safe encoding
  s.encode.replace('+', '-').replace('/', '_')

proc urlsafeBase64Decode*(s: string): string {.inline.} =
  ## URL-safe and Cookie-safe decoding
  s.replace('-', '+').replace('_', '/').decode
