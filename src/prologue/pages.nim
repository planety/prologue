import htmlgen

proc errorPage*(errorMsg: string, version: string): string =
  return html(head(title(errorMsg)),
              body(h1(errorMsg),
                   "<hr/>",
                   p("Prologue " & version),
                   style = "text-align: center;"
    ),
    xmlns = "http://www.w3.org/1999/xhtml")


proc loginPage*(): string =
  return html(form(action = "/login",
     `method` = "post",
     "Username: ", input(name = "username", `type` = "text"),
     "Password: ", input(name = "password", `type` = "password"),
     input(value = "login", `type` = "submit")),
     xmlns = "http://www.w3.org/1999/xhtml")
