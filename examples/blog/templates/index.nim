import strtabs, strformat

import karax / [karaxdsl, vdom]
import prologue

import
  share/head,
  share/nav


# This is 'primary' section for our template it separated for convenience
proc indexSection*(ctx: Context, posts: seq[seq[string]]): VNode =
  result = buildHtml(main(class = "content")):
    #h3: text "Posts"
    let poi = ctx.session.getOrDefault("userId")
    if poi.len != 0:
      a(class = "action", href = "/blog/create"): text "Create new post"

    if posts.len > 0:
      for post in posts:
        tdiv(class = "post"):
          tdiv:
            h3: text post[3]
            tdiv(class = "about"): text fmt"""by {post[1]} on {post[2]}"""
          p(class = "body"): text post[4]
          if poi == post[1]:
            a(class = "action", href = fmt"""/blog/update/{post[0]}"""): text "Edit"
    else:
      tdiv(class = "is-empty"):
        text "This blog is empty"


# This is composed HTML view that should be exposed to relevant route/controller/view
# There is no 'extend' feature so we 'include' our html sections/partials/html chunks into final template
proc indexPage*(ctx: Context, title: string, posts: seq[seq[string]]): string =
  let head = sharedHead(ctx, title) # 'shared' head part
  let nav = sharedNav(ctx) # 'shared' navbar
  let posts = indexSection(ctx, posts) # 'primary' section from above
  let vNode = buildHtml(html):
    # Call our sections
    head
    nav
    posts

  # Don't forget Doctype declaration to avoid any failing validation tests
  # like this one https://validator.w3.org/
  result = "<!DOCTYPE html>\n" & $vNode
