# "Test Import"
block:
  # "import can import"
  block:
    doAssert compiles("import ../../src/prologue/auth/auth")
    doAssert compiles("import ../../src/prologue/i18n/i18n")
    doAssert compiles("import ../../src/prologue/middlewares/middlewares")
    doAssert compiles("import ../../src/prologue/openapi/openapi")
    doAssert compiles("import ../../src/prologue/security/security")
    doAssert compiles("import ../../src/prologue/validate/validate")
