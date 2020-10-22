import prologue

import ./views


let
  indexPatterns* = @[
    pattern("/", views.read, @[HttpGet], name = "index")
  ]
  authPatterns* = @[
    pattern("/login", views.login, @[HttpGet, HttpPost], name = "login"),
    pattern("/register", views.register, @[HttpGet, HttpPost]),
    pattern("/logout", views.logout, @[HttpGet, HttpPost]),
  ]
  blogPatterns* = @[
    pattern("/create", views.create, @[HttpGet, HttpPost], name = "create"),
    pattern("/update/{id}", views.update, @[HttpGet, HttpPost],
        name = "update"),
    pattern("/delete/{id}", views.delete, @[HttpGet], name = "delete")
  ]
