import ../../src/prologue

import views


const
  authPatterns* = @[
    pattern("/login", views.login, @[HttpGet, HttpPost], name = "login"),
    pattern("/register", views.register, @[HttpGet, HttpPost])
  ]
