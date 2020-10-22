import karax / [karaxdsl, vdom]
import prologue

import
  share/head,
  share/nav


proc editSection*(ctx: Context, post: seq[string] = @[]): VNode =
  var
    id = ""
    title = ""
    content = ""

  if post.len > 0:
    id = post[0]
    title = post[3]
    content = post[4]

  result = buildHtml(main(class = "content")):
    h4: text "Edit post"
    form(`method` = "post"):
      if id.len > 0:
        input(`type` = "hidden", name = "id", value = id)
      label(`for` = "title"): text "Blog title"
      input(name = "title", id = "title", required = "required", value = title)
      label(`for` = "content"): text "Blog content"
      textarea(name = "content", id = "content", required = "required"):
        text content
      tdiv:
        input(`type` = "submit", value = "Save")
        a(href = "/"): text "Cancel"
        if id.len > 0:
          a(href = "/blog/delete/" & id): text "Delete"


proc editPage*(ctx: Context, title: string, post: seq[string] = @[]): string =
  let head = sharedHead(ctx, title)
  let nav = sharedNav(ctx)
  let edit = editSection(ctx, post)
  let vNode = buildHtml(html):
    head
    nav
    edit

  result = "<!DOCTYPE html>\n" & $vNode
