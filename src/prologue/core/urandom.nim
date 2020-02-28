from nimcrypto import randomBytes


from ../core/types import SecretKey


proc randomString*(size: int): string =
  result = newString(size)
  discard randomBytes(result)

proc randomSecretKey*(size: int): SecretKey =
  var buffer = newString(size)
  discard randomBytes(buffer)
  result = SecretKey(buffer)
