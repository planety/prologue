import karax / [karaxdsl, vdom]
import ../../../src/prologue


const
  name* = "Prologue"

proc formPage*(title, action: string): string =
  let vnode = buildHtml(section(class = "content")):
    h1: text title
    body:
      form(`method`="post"):
        label(`for`="username"): text "Username"
        input(name="username", id = "username", required = "required")
        label(`for`="password"): text "Password"
        input(`type`="password", name="password", id="password", required = "required")
        input(`type`="submit", value=action)
  result = $vnode

proc basePage*(ctx: Context, appName, title, action: string): string =
  let userName = getPostParams("username")
  let vnode = buildHtml(html):
    title: text title
    link(rel = "stylesheet", href = "/static/style.css")
    nav: 
      h1: text appName
      ul:
        if userName == "":
          li: a(href = "/register"): text "Register"
          li: a(href = "/login"): text "Log In"
        else:
          li: span: text userName
          li: a(href = "/logout"): text "Log Out"
    verbatim formPage(title, action)
  result = $vnode
