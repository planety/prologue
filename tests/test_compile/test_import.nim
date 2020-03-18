import unittest


suite "Test Import":
  test "import can import":
    check:
      compiles("import ../../src/prologue/auth/auth")
      compiles("import ../../src/prologue/i18n/i18n")
      compiles("import ../../src/prologue/middlewares/middlewares")
      compiles("import ../../src/prologue/openapi/openapi")
      compiles("import ../../src/prologue/security/security")
      compiles("import ../../src/prologue/validate/validate")
