import asyncdispatch, httpcore
import strutils

import ../context, ../response, core

import regex

when not defined(production):
  import ../naiverequest

const
  AllHttpMethod = @["get", "post", "put", "patch", "options", "delete"]
  AllHttpMethodEnum = @[HttpGet, HttpPost, HttpPut, HttpPatch, HttpOptions, HttpDelete]




proc isAllowedOrigin(origin: string, allowAllOrigins: bool,
    allowOrigins: sink seq[string], allowOriginRegex: sink Regex): bool =
  if allowAllOrigins:
    return true

  var m: RegexMatch
  if origin.match(allowOriginRegex, m):
    return true

  return origin in allowOrigins


proc CORSMiddleware*(
  allowOrigins: seq[string] = @[],
  allowOriginRegex: Regex = re"",
  allowMethods: seq[string] = @["get"],
  allowHeaders: seq[string] = @[],
  exposeHeaders: seq[string] = @[],
  allowCredentials = false,
  maxAge = 7200,
  ): HandlerAsync =

  result = proc(ctx: Context) {.async.} =
    var
      reqHeaders = ctx.request.headers

    let
      origin = reqHeaders.getOrDefault("origin")

    ## don't have origin
    ## simple headers
    ## preflight headers

    if origin == "":
      await switch(ctx)
      return

    let
      allowAllHeaders = "*" in allowHeaders
      allowAllOrigins = "*" in allowOrigins

    var
      allowMethodsSeq: seq[string]

    if "*" in allowMethods:
      allowMethodsSeq = AllHttpMethod

    if ctx.request.reqMethod == HttpOptions and reqHeaders.hasKey("access-control-request-method"):
      var
        preflightHeaders = newHttpHeaders()
        errorMsg: seq[string] = @[]

      if "*" in allowOrigins:
        preflightHeaders["Access-Control-Allow-Origin"] = "*"
      else:
        preflightHeaders["Vary"] = "Origin"

      preflightHeaders["Access-Control-Allow-Methods"] = allowMethodsSeq
      preflightHeaders["Access-Control-Max-Age"] = $maxAge

      if allowHeaders.len != 0 and not allowAllHeaders:
        preflightHeaders["Access-Control-Allow-Headers"] = allowHeaders
      if allow_credentials:
        preflightHeaders["Access-Control-Allow-Credentials"] = "true"

      if isAllowedOrigin(origin, allowAllOrigins, allowOrigins,
          allowOriginRegex) and not allowAllOrigins:
        preflightHeaders["Access-Control-Allow-Origin"] = origin
      else:
        errorMsg.add "origin"

      if ctx.request.reqMethod notin AllHttpMethodEnum:
        errorMsg.add "method"

      let accessControlAllowHeaders = seq[string](reqHeaders["Access-Control-Allow-Headers"])
      if allowAllHeaders and accessControlAllowHeaders.len != 0:
        preflightHeaders["Access-Control-Allow-Headers"] = accessControlAllowHeaders
      elif accessControlAllowHeaders.len != 0:
        for header in accessControlAllowHeaders:
          if header notin allowHeaders:
            errorMsg.add "headers"

      if errorMsg.len != 0:
        await ctx.request.respond(plainTextResponse("Disallowed CORS " &
            errorMsg.join(", "), Http403, preflightHeaders))
      else:
        await ctx.request.respond(plainTextResponse("Ok", Http200,
            preflightHeaders))
      return

    var
      simpleHeaders = newHttpHeaders()

    if "*" in allowOrigins:
      simpleHeaders["Access-Control-Allow-Origin"] = "*"

    if allowCredentials:
      simpleHeaders["Access-Control-Allow-Credentials"] = "true"

    if exposeHeaders.len != 0:
      simpleHeaders["Access-Control-Expose-Headers"] = exposeHeaders

    for httpMethod in allowMethods:
      let value = toLowerAscii(httpMethod)
      if value in AllHttpMethod:
        allowMethodsSeq.add value

    for key, value in simpleHeaders:
      reqHeaders[key] = value

    let
      hasCookie = reqHeaders.hasKey("cookie")

    if allowAllOrigins and hasCookie:
      reqHeaders["Access-Control-Allow-Origin"] = origin

    elif not allowAll_Origins and isAllowedOrigin(origin, allowAllOrigins,
        allowOrigins, allowOriginRegex):
      reqHeaders["Access-Control-Allow-Origin"] = origin
      reqHeaders.add("vary", "Origin")

    await switch(ctx)
