import std/htmlgen


func loginPage*(): string =
  return html(form(action = "/login",
      `method` = "post",
      "Username: ", input(name = "username", `type` = "text"),
      "Password: ", input(name = "password", `type` = "password"),
      input(value = "login", `type` = "submit")),
      xmlns = "http://www.w3.org/1999/xhtml")

func loginGetPage*(): string =
  return html(form(action = "/loginpage",
      `method` = "get",
      "Username: ", input(name = "username", `type` = "text"),
      "Password: ", input(name = "password", `type` = "password"),
      input(value = "login", `type` = "submit")),
      xmlns = "http://www.w3.org/1999/xhtml")
