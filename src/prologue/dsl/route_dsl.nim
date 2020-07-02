from ../core/application import Prologue
import macros,strutils

proc collectMethods(node:NimNode, o:var NimNode) {.compileTime.} = 
  for n in node:
    if n.kind == nnkIdent and n.repr in ["get","post","put","delete","head","options"]:
      o.add newIdentNode( "Http" & capitalizeAscii n.repr)
    else:
      collectMethods(n,o)

proc collectCall(node:NimNode, o:var NimNode) {.compileTime.} = 
  for n in node:
    if n.kind == nnkCall:
      o.add n
    else:
      collectCall(n,o)

proc getHandler(node:NimNode):NimNode {.compileTime.} = 
  for n in node:
    if n.kind == nnkIdent and n.repr notin ["get","post","put","delete","head","options"]:
      result = n
      break;
    else:
      result = getHandler(n)

proc getPath(node:NimNode):NimNode {.compileTime.} = 
  for n in node:
    if n.kind == nnkStrLit or n.kind == nnkCallStrLit:
      result = n
      break;
    else:
      result = getPath(n)

macro route*(app: Prologue, routes: untyped): untyped =
  result = nnkStmtList.newTree()
  for element in routes:
    expectKind element, nnkCommand 
    var mets = nnkBracket.newTree()
    collectMethods(element,mets)
    var methods = nnkPrefix.newTree(
      newIdentNode("@"),
      mets
    )
    var calls = nnkBracket.newTree()
    collectCall(element,calls)
    var mids = nnkExprEqExpr.newTree(
      newIdentNode("middlewares"),
      nnkPrefix.newTree(
        newIdentNode("@"),
        calls
      )
    )
    let path = getPath element 
    let handler = getHandler element 
    var theCall = nnkCall.newTree(
      nnkDotExpr.newTree(
        app,
        newIdentNode("addRoute")
      ),
      path,
      handler,
      methods,
    )
    if calls.len > 0:
      theCall.add mids
    result.add theCall
    
