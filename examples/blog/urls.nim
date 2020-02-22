import ../../src/prologue

import views


const urlPatterns* = @[
  pattern("/login", views.login, @[HttpGet, HttpPost]),
  pattern("/register", views.register, @[HttpGet, HttpPost])
]
