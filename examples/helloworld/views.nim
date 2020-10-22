import prologue
import std/[tables, logging]


proc articles*(ctx: Context) {.async.} =
  resp $ctx.getPathParams("num", 1)

proc hello*(ctx: Context) {.async.} =
  # await sleepAsync(3000)
  resp "<h1>Hello, Prologue!</h1>"
  if true:
    raise newException(ValueError, "can't be reached")

proc index*(ctx: Context) {.async.} =
  await ctx.staticFileResponse("index.html", "static")

proc helloName*(ctx: Context) {.async.} =
  logging.debug ctx.getPathParams("name")
  resp "<h1>Hello, " & ctx.getPathParams("name", "World") & "</h1>"

proc home*(ctx: Context) {.async.} =
  logging.debug urlFor(ctx, "index")
  logging.debug urlFor(ctx, "helloname", {"name": "flywind"}, {"age": "20"})
  logging.debug ctx.request.queryParams.getOrDefault("name", "")
  resp redirect(urlFor(ctx, "helloname", {"name": "flywind"}, {"age": "20", "hobby": "Nim"}), Http302)

proc testRedirect*(ctx: Context) {.async.} =
  resp redirect("/hello", Http302)

proc login*(ctx: Context) {.async.} =
  resp loginPage()

proc do_login*(ctx: Context) {.async.} =
  logging.debug "-----------------------------------------------------"
  logging.debug ctx.request.postParams
  resp redirect("/hello/Nim")

proc multiPart*(ctx: Context) {.async.} =
  resp multiPartPage()

proc do_multiPart*(ctx: Context) {.async.} =
  logging.debug ctx.request.formParams["username"].body
  logging.debug ctx.request.formParams["password"].body
  resp redirect("/login")

proc upload*(ctx: Context) {.async.} =
  await ctx.staticFileResponse("upload.html", "static")

proc do_upload*(ctx: Context) {.async.} =
  logging.debug ctx.request.formParams
  resp ctx.request.formParams["file"].body
