include ../../../src/prologue/core/context
import std/[unittest]


discard """
  joinable: false
"""

# "Test Context"
block:
  # "multiMatch can work"
  # TODO support wildcard

  doAssert multiMatch("/hello/{name}/ok/{age}/io", @{"name": "flywind",
                      "age": "20"}) == "/hello/flywind/ok/20/io"
  doAssert multiMatch("/api/homepage") == "/api/homepage"
  doAssert multiMatch("", @{"name": "flywind"}) == ""

block:
  var ctx = new Context
  init(ctx, Request(), Response(), GlobalScope())
  doAssert not ctx.handled
  doAssert ctx.size == 0
  doAssert ctx.first

  doAssertRaises(AbortError):
    abortExit(ctx)


suite "getQueryParamsOption":
  test "Given the query param exists, When the query param is queried, Then return the query param":
    #Given
    var ctx = new Context
    ctx.request.queryParams = newStringTable(StringTableMode.modeCaseInsensitive)
    let expectedValue = "testValue"
    ctx.request.queryParams["param"] = expectedValue
    
    #When
    let queryParam = ctx.getQueryParamsOption("param")

    #Then
    check queryParam.isSome()
    check queryParam.get() == expectedValue
  
  test "Given no query params, When a query param is queried, Then return none(string)":
    #Given
    var ctx = new Context
    ctx.request.queryParams = newStringTable(StringTableMode.modeCaseInsensitive)
    
    #When
    let queryParam = ctx.getQueryParamsOption("param")

    #Then
    check queryParam.isNone()
  
  test "Given a query param, When a query param is queried that is not in the given params, Then return none(string)":
    #Given
    var ctx = new Context
    ctx.request.queryParams = newStringTable(StringTableMode.modeCaseInsensitive)
    let expectedValue = "testValue"
    ctx.request.queryParams["param"] = expectedValue
    
    #When
    let queryParam = ctx.getQueryParamsOption("invalidParam")

    #Then
    check queryParam.isNone()


suite "getQueryParams":
  test "Given the query param exists, When the query param is queried, Then return the query param":
    #Given
    var ctx = new Context
    ctx.request.queryParams = newStringTable(StringTableMode.modeCaseInsensitive)
    let expectedValue = "testValue"
    ctx.request.queryParams["param"] = expectedValue
    
    #When
    let queryParam = ctx.getQueryParams("param")

    #Then
    check queryParam == expectedValue
  
  test "Given no query params, When a query param is queried and no default is specified, Then return an empty string":
    #Given
    var ctx = new Context
    ctx.request.queryParams = newStringTable(StringTableMode.modeCaseInsensitive)
    
    #When
    let queryParam = ctx.getQueryParams("param")

    #Then
    let expectedValue = ""
    check queryParam == expectedValue
  
  test "Given no query params, When a query param is queried and a default is specified, Then return the default":
    #Given
    var ctx = new Context
    ctx.request.queryParams = newStringTable(StringTableMode.modeCaseInsensitive)
    
    #When
    let queryParam = ctx.getQueryParams("param", "defaultValue")

    #Then
    check queryParam == "defaultValue"
  
  test "Given a query param, When a query param is queried that is not in the given params, Then return an empty string":
    #Given
    var ctx = new Context
    ctx.request.queryParams = newStringTable(StringTableMode.modeCaseInsensitive)
    let expectedValue = "testValue"
    ctx.request.queryParams["param"] = expectedValue
    
    #When
    let queryParam = ctx.getQueryParams("differentParam")

    #Then
    check queryParam == ""


suite "getPathParamsOption":
  test "Given a param exists, When the param is queried, Then return the param":
    #Given
    var ctx = new Context
    ctx.request.pathParams = newStringTable(StringTableMode.modeCaseInsensitive)
    let expectedValue = "testValue"
    ctx.request.pathParams["param"] = expectedValue
    
    #When
    let param = ctx.getPathParamsOption("param")

    #Then
    check param.isSome()
    check param.get() == expectedValue
  
  test "Given no params, When a param is queried and no default is specified, Then return none":
    #Given
    var ctx = new Context
    ctx.request.pathParams = newStringTable(StringTableMode.modeCaseInsensitive)

    #When
    let param = ctx.getPathParamsOption("param")

    #Then
    check param.isNone()
  
  test "Given a param, When a param is queried that is not in the given params, Then return none":
    #Given
    var ctx = new Context
    ctx.request.pathParams = newStringTable(StringTableMode.modeCaseInsensitive)
    let expectedValue = "testValue"
    ctx.request.pathParams["param"] = expectedValue
    
    #When
    let param = ctx.getPathParamsOption("differentParam")

    #Then
    check param.isNone()


suite "getPathParams":
  test "Given a param exists, When the param is queried, Then return the param":
    #Given
    var ctx = new Context
    ctx.request.pathParams = newStringTable(StringTableMode.modeCaseInsensitive)
    let expectedValue = "testValue"
    ctx.request.pathParams["param"] = expectedValue
    
    #When
    let param = ctx.getPathParams("param")

    #Then
    check param == expectedValue
  
  test "Given no params, When a param is queried and no default is specified, Then return an empty string":
    #Given
    var ctx = new Context
    ctx.request.pathParams = newStringTable(StringTableMode.modeCaseInsensitive)

    #When
    let param = ctx.getPathParams("param")

    #Then
    let expectedValue = ""
    check param == expectedValue
  
  test "Given no params, When a param is queried and a default is specified, Then return the default":
    #Given
    var ctx = new Context
    ctx.request.pathParams = newStringTable(StringTableMode.modeCaseInsensitive)
    
    #When
    let param = ctx.getPathParams("param", "defaultStringValue")
  
    #Then
    check param.type is string
    check param == "defaultStringValue"
  
  test "Given a param, When a param is queried that is not in the given params, Then return an empty string":
    #Given
    var ctx = new Context
    ctx.request.pathParams = newStringTable(StringTableMode.modeCaseInsensitive)
    let expectedValue = "testValue"
    ctx.request.pathParams["param"] = expectedValue
    
    #When
    let param = ctx.getPathParams("differentParam")

    #Then
    check param == ""


suite "getFormParamsOption":
  test "Given a param exists, When the param is queried, Then return the param":
    #Given
    var ctx = new Context
    ctx.request.formParams = initFormPart()
    let expectedValue = "testValue"
    ctx.request.formParams["param"] = expectedValue
    
    #When
    let param = ctx.getFormParamsOption("param")

    #Then
    check param.isSome()
    check param.get() == expectedValue
  
  test "Given no params, When a param is queried and no default is specified, Then return none":
    #Given
    var ctx = new Context
    ctx.request.formParams = initFormPart()
    
    #When
    let param = ctx.getFormParamsOption("param")

    #Then
    check param.isNone()
  
  test "Given a param, When a param is queried that is not in the given params, Then return none":
    #Given
    var ctx = new Context
    ctx.request.formParams = initFormPart()
    let expectedValue = "testValue"
    ctx.request.formParams["param"] = expectedValue
    
    #When
    let param = ctx.getFormParamsOption("differentParam")

    #Then
    check param.isNone()


suite "getFormParams":
  test "Given a param exists, When the param is queried, Then return the param":
    #Given
    var ctx = new Context
    ctx.request.formParams = initFormPart()
    let expectedValue = "testValue"
    ctx.request.formParams["param"] = expectedValue
    
    #When
    let param = ctx.getFormParams("param")

    #Then
    check param == expectedValue
  
  test "Given no params, When a param is queried and no default is specified, Then return an empty string":
    #Given
    var ctx = new Context
    ctx.request.formParams = initFormPart()

    #When
    let param = ctx.getFormParams("param")

    #Then
    let expectedValue = ""
    check param == expectedValue
  
  test "Given no params, When a param is queried and a default is specified, Then return the default":
    #Given
    var ctx = new Context
    ctx.request.formParams = initFormPart()

    #When
    let param = ctx.getFormParams("param", "defaultStringValue")
  
    #Then
    check param.type is string
    check param == "defaultStringValue"
  
  test "Given a param, When a param is queried that is not in the given params, Then return an empty string":
    #Given
    var ctx = new Context
    ctx.request.formParams = initFormPart()
    let expectedValue = "testValue"
    ctx.request.formParams["param"] = expectedValue
    
    #When
    let param = ctx.getFormParams("differentParam")

    #Then
    check param == ""

