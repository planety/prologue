import ../../src/prologue


import controllers


let urlPatterns* = @[
  # strip latter
  pattern("/", home),
  pattern("/", home, HttpPost),
  pattern("/home", home),
  pattern("/login", login),
  pattern("/login", do_login, HttpPost),
  pattern("/redirect", testRedirect),
  pattern("/multipart", multipart)
]
