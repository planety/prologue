import karax / [karaxdsl, vdom]
import ../../../src/prologue


const
  name* = "Prologue"


proc formPage*(header, action: string): Vnode =
  result = buildHtml(section(class = "content")):
    header: h1: text header
    form(`method` = "post"):
      label(`for` = "username"): text "Username"
      input(name = "username", id = "username", required = "required")
      label(`for` = "password"): text "Password"
      input(`type` = "password", name = "password", id = "password",
          required = "required")
      input(`type` = "submit", value = action)

proc basePage*(ctx: Context, appName, title: string, content: VNode): string =
  let userName = getPostParams("username")
  let vNode = buildHtml(html):
    title: text title & " - " & appName
    link(rel = "stylesheet", href = "/static/style.css")
    nav:
      h1: a(href = "/blog/index"): text appName
      ul:
        if userName.len == 0:
          li: a(href = "/auth/register"): text "Register"
          li: a(href = "/auth/login"): text "Log In"
        else:
          li: span: text userName
          li: a(href = "/auth/logout"): text "Log Out"
    content
  result = $vNode
