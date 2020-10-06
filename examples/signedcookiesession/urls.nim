import ../../src/prologue

import ./views


let urlPatterns* = @[
  # strip latter
  pattern("/", hello),
  pattern("/login", login),
  pattern("/logout", logout)
]
