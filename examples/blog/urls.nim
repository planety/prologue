import ../../src/prologue

import views


const
  authPatterns* = @[
    pattern("/login", views.login, @[HttpGet, HttpPost]),
    pattern("/register", views.register, @[HttpGet, HttpPost])
  ]
