import std/htmlgen
import ./constants


func errorPage*(errorMsg: string): string {.inline.} =
  ## Error pages for HTTP 404.
  result = html(head(title(errorMsg)),
                body(h1(errorMsg),
                     "<hr/>",
                     p("Prologue " & PrologueVersion),
                     style = "text-align: center;"),
                xmlns = "http://www.w3.org/1999/xhtml")

func loginPage*(): string {.inline.} =
  ## Login pages.
  result = html(form(action = "/login",
                `method` = "post",
                "Username: ", input(name = "username", `type` = "text"),
                "Password: ", input(name = "password", `type` = "password"),
                input(value = "login", `type` = "submit")),
                xmlns = "http://www.w3.org/1999/xhtml")

func multiPartPage*(): string {.inline.} =
  ## Multipart pages for uploading files.
  result = html(form(action = "/multipart?firstname=red green&lastname=tenth",
               `method` = "post", enctype = "multipart/form-data",
                input(name = "username", `type` = "text", value = "play game"),
                input(name = "password", `type` = "password", value = "start"),
                input(value = "submit", `type` = "submit")),
                xmlns = "http://www.w3.org/1999/xhtml")

func internalServerErrorPage*(): string {.inline.} =
  ## Internal server error pages for HTTP 500.
  result = """<html>

<head>
  <title>500 Internal Server Error</title>
</head>

<body>
  <h1>500 Internal Server Error</h1>
  <div>
    <p>
      The Server encountered an internal error and unable to complete
      you request.
    </p>
  </div>
</body>

</html>
"""
