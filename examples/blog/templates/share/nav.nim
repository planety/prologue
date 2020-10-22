import prologue
import karax/[karaxdsl, vdom]


proc sharedNav*(ctx: Context): VNode =
  let fullname = ctx.session.getOrDefault("userFullname", "")
  let vNode = buildHtml(header):
    nav:
      tdiv(class = "brand"):
        a(href = "/"):
          text "Blog Example"
      ul:
        if fullname.len == 0:
          li: a(href = "/auth/register"): text "Register"
          li: a(href = "/auth/login"): text "Log In"
        else:
          li: span: text fullname
          li: a(href = "/auth/logout"): text "Log Out"

  return vNode
