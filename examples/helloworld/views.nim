import ../../src/prologue


proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc docs*(ctx: Context) {.async.} =
  await ctx.staticFileResponse("docs.html", "docs")

proc redocs*(ctx: Context) {.async.} = 
  await ctx.staticFileResponse("redocs.html", "docs")

proc docsjson*(ctx: Context) {.async.} =
  await ctx.staticFileResponse("openapi.json", "docs")

proc home*(ctx: Context) {.async.} =
  echo ctx.request.queryParams.getOrDefault("name", "")
  resp "<h1>Home</h1>"

proc index*(ctx: Context) {.async.} =
  await ctx.staticFileResponse("index.html", "static")

proc helloName*(ctx: Context) {.async.} =
  echo getPathParams("name")
  resp "<h1>Hello, " & getPathParams("name", "Prologue") & "</h1>"

proc testRedirect*(ctx: Context) {.async.} =
  resp redirect("/hello")

proc login*(ctx: Context) {.async.} =
  resp loginPage()

proc do_login*(ctx: Context) {.async.} =
  echo "-----------------------------------------------------"
  echo ctx.request.postParams
  echo getPostParams("username", "")
  echo getPostParams("password", "")
  resp redirect("/hello/Nim")

proc multiPart*(ctx: Context) {.async.} =
  resp multiPartPage()

proc do_multiPart*(ctx: Context) {.async.} =
  resp redirect("/login")
