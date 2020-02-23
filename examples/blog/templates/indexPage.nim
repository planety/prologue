import strtabs, strformat
import base
import karax / [karaxdsl, vdom]
import ../../../src/prologue


proc indexBase*(ctx: Context, posts: seq[StringTableRef]): VNode =
  result = buildHtml(section(class = "content")):
    header:
      h1: text "Posts"
      if ctx.session.getOrDefault("userId") != "":
        a(class = "action", href = "/blog/create"): text "New"

    for post in posts:
      article(class = "post"):
        header:
          tdiv:
            h1: text post.getOrDefault("title")
            tdiv(class = "about"): text fmt"""by {post.getOrDefault("username")} on {post.getOrDefault("created")}"""
          if ctx.session.getOrDefault("userId") == post.getOrDefault("userId"):
            a(class = "action", href = fmt"""/blog/update{post.getOrDefault("id")}"""): text "Edit"
        p(class = "body"): text post.getOrDefault("body")
