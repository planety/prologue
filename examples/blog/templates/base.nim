import karax / [karaxdsl, vdom]
import ../../../src/prologue

import ../views


proc homePage*(title: string): string =
  let vnode = buildHtml(html):
    title: text title
    link(rel = "stylesheet", href = "/static/style.css")
    nav:
      h1: 
        a(href = "")
