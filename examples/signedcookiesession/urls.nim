import prologue

import ./views


const urlPatterns* = @[
  pattern("/", hello),
  pattern("/login", login),
  pattern("/logout", logout)
]
