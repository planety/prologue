import ../../src/prologue
import tables, logging


proc articles*(ctx: Context) {.async.} =
  resp $getPathParams("num", 1)

proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc docs*(ctx: Context) {.async.} =
  await ctx.staticFileResponse("docs.html", "docs")

proc redocs*(ctx: Context) {.async.} =
  await ctx.staticFileResponse("redocs.html", "docs")

proc docsjson*(ctx: Context) {.async.} =
  await ctx.staticFileResponse("openapi.json", "docs")

proc index*(ctx: Context) {.async.} =
  await ctx.staticFileResponse("index.html", "static")

proc helloName*(ctx: Context) {.async.} =
  logging.debug getPathParams("name")
  resp "<h1>Hello, " & getPathParams("name", "World") & "</h1>"

proc home*(ctx: Context) {.async.} =
  echo urlFor(ctx, index)
  
  logging.debug ctx.request.queryParams.getOrDefault("name", "")
  resp(redirect urlFor(ctx, helloName, ("name", "flywind")))

proc testRedirect*(ctx: Context) {.async.} =
  resp redirect("/hello")

proc login*(ctx: Context) {.async.} =
  resp loginPage()

proc do_login*(ctx: Context) {.async.} =
  logging.debug "-----------------------------------------------------"
  logging.debug ctx.request.postParams
  logging.debug ctx.request.formParams["username"].body
  logging.debug ctx.request.formParams["password"].body
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
