import ../../src/prologue

import ./views


let urlPatterns* = @[
  pattern("/", hello),
  pattern("/login", login),
  pattern("/logout", logout),
  pattern("/print", print)
]
