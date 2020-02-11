import asyncdispatch, httpcore
import strutils

import ../context, core

import regex

when not defined(production):
  import ../naiverequest

const
  AllHttpMethod = @[HttpGet, HttpPost, HttpPut, HttpPatch, HttpOptions, HttpDelete]


proc CORSMiddleware*(
  allowOrigins: seq[string] = @[],
  allowOriginRegex: Regex = re"",
  allowMethods: seq[string] = @[],
  allowHeaders: seq[string] = @[],
  exposeHeaders: seq[string] = @[],
  allowCredentials = false,
  maxAge = 7200,
  ): HandlerAsync =
  result = proc(ctx: Context) {.async.} =
    let
      headers = ctx.request.headers
      origin = headers.getOrDefault("origin")

    var allowMethodsSeq: seq[HttpMethod] 

    if "*" in allowMethods:
      allowMethodsSeq = AllHttpMethod

    for httpMethod in allowMethods:
      case toLowerAscii(httpMethod)
      of "get":
        allowMethodsSeq.add HttpGet
      of "post":
        allowMethodsSeq.add HttpPost
      of "put":
        allowMethodsSeq.add HttpPut
      of "delete":
        allowMethodsSeq.add HttpDelete
      of "patch":
        allowMethodsSeq.add HttpPatch
      of "options":
        allowMethodsSeq.add HttpOptions
      else:
        # TODO May raise
        discard

    ## don't have origin
    ## simple headers
    ## preflight headers

    if origin == "":
      await switch(ctx)
      return

    if ctx.request.reqMethod == HttpOptions and headers.hasKey("access-control-request-method"):
      await switch(ctx)
      return


    await switch(ctx)