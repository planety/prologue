import ../../../src/prologue/core/encode


block:
  static: 
    doAssert base64Encode("a") == "YQ=="
  doAssert base64Encode("a") == "YQ=="

block:
  doAssert base64Encode("Hello World") == "SGVsbG8gV29ybGQ="
  doAssert base64Encode("leasure.") == "bGVhc3VyZS4="
  doAssert base64Encode("easure.") == "ZWFzdXJlLg=="
  doAssert base64Encode("asure.") == "YXN1cmUu"
  doAssert base64Encode("sure.") == "c3VyZS4="
  doAssert base64Encode([1,2,3]) == "AQID"
  doAssert base64Encode(['h','e','y']) == "aGV5"

  doAssert base64Encode("") == ""
  doAssert base64Decode("") == ""

  const testInputExpandsTo76 = "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  const testInputExpands = "++++++++++++++++++++++++++++++"
  const longText = """Man is distinguished, not only by his reason, but by this
    singular passion from other animals, which is a lust of the mind,
    that by a perseverance of delight in the continued and indefatigable
    generation of knowledge, exceeds the short vehemence of any carnal
    pleasure."""
  const tests = ["", "abc", "xyz", "man", "leasure.", "sure.", "easure.",
                 "asure.", longText, testInputExpandsTo76, testInputExpands]

  doAssert base64Decode("Zm9v\r\nYmFy\r\nYmF6") == "foobarbaz"

  for t in items(tests):
    doAssert base64Decode(base64Encode(t)) == t

  const invalid = "SGVsbG\x008gV29ybGQ="
  try:
    doAssert base64Decode(invalid) == "will throw error"
  except ValueError:
    discard

  block base64urlSafe:
    doAssert urlsafeBase64Encode("c\xf7>") == "Y_c-"
    doAssert base64Encode("c\xf7>") == "Y/c+" 
    doAssert base64Decode("Y/c+") == base64Decode("Y_c-")
    # Output must not change with safe=true
    doAssert urlsafeBase64Encode("Hello World") == "SGVsbG8gV29ybGQ="
    doAssert urlsafeBase64Encode("leasure.")  == "bGVhc3VyZS4="
    doAssert urlsafeBase64Encode("easure.") == "ZWFzdXJlLg=="
    doAssert urlsafeBase64Encode("asure.") == "YXN1cmUu"
    doAssert urlsafeBase64Encode("sure.") == "c3VyZS4="
    doAssert urlsafeBase64Encode([1,2,3]) == "AQID"
    doAssert urlsafeBase64Encode(['h','e','y']) == "aGV5"
    doAssert urlsafeBase64Encode("") == ""
    doAssert urlsafeBase64Encode("the quick brown dog jumps over the lazy fox") == "dGhlIHF1aWNrIGJyb3duIGRvZyBqdW1wcyBvdmVyIHRoZSBsYXp5IGZveA=="
