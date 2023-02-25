#           nest
#    The MIT License (MIT)
# Copyright (c) 2016 Kevin Dean


# Copyright 2020 Zeshen Xing
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


import std/[hashes, strutils, strtabs, options, critbits, sequtils, parseutils]

from ./basicregex import Regex, RegexMatch, match, groupNames, groupFirstCapture
import ./context
import ./request
import ./httpcore/httplogue
import ./httpexception


const 
  pathSeparator = '/'
  allowedCharsInUrl = {'a'..'z', 'A'..'Z', '0'..'9', '-', '.', '_', '~', '%', '\'', pathSeparator}
  wildcard = '*'
  startParam = '{'
  endParam = '}'
  greedyIndicator = '$'
  specialSectionStartChars = {pathSeparator, wildcard, startParam}
  allowedCharsInPattern = allowedCharsInUrl + {wildcard, startParam,
                                  endParam, greedyIndicator}


type
  UrlPattern* = tuple
    route: string
    matcher: HandlerAsync
    httpMethod: seq[HttpMethod]
    name: string
    middlewares: seq[HandlerAsync]


func initPath*(route: string, httpMethod = HttpGet): Path {.inline.} =
  Path(route: route, httpMethod: httpMethod)

func initRePath*(route: Regex, httpMethod = HttpGet): RePath {.inline.} =
  RePath(route: route, httpMethod: httpMethod)

func pattern*(route: string, handler: HandlerAsync, httpMethod = HttpGet,
              name = "", middlewares: openArray[HandlerAsync] = @[]
): UrlPattern {.inline.}  =
  (route, handler, @[httpMethod], name, @middlewares)

func pattern*(route: string, handler: HandlerAsync, 
              httpMethod: openArray[HttpMethod], name = "", 
              middlewares: openArray[HandlerAsync] = @[]
): UrlPattern {.inline.} =
  (route, handler, @httpMethod, name, @middlewares)

func hash*(x: Path): Hash {.inline.} =
  var h: Hash = 0
  h = h !& hash(x.route)
  h = h !& hash(x.httpMethod)
  result = !$h

func newReRouter*(): ReRouter {.inline.} =
  ReRouter(callable: newSeq[(RePath, PathHandler)]())

func add*(reRouter: var ReRouter, pairs: (RePath, PathHandler)) {.inline.} =
  reRouter.callable.add(pairs)

iterator items*(reRouter: ReRouter): (RePath, PathHandler) =
  for item in reRouter.callable.items:
    yield item

func `$`*(piece: BasePatternNode): string =
  case piece.kind
  of ptrnParam, ptrnText:
    result = $(piece.kind) & ":" & piece.value
  of ptrnWildcard:
    result = $(piece.kind)

func `$`*(node: PatternNode): string =
  case node.kind
  of ptrnParam, ptrnText:
    result = $(node.kind) & ":value=" & node.value & ", "
  of ptrnWildcard:
    result = $(node.kind) & ":"

  result.add "leaf=" & $node.isLeaf & ", terminator=" &
                    $node.isTerminator & ", greedy=" & $node.isGreedy

func `==`(node: PatternNode, bnode: BasePatternNode): bool =
  result = (node.kind == bnode.kind)

  if result:
    case node.kind
    of ptrnText, ptrnParam:
      result = (node.value == bnode.value)
    else:
      discard

func printRoutingTree(node: PatternNode, tabs: int = 0) =
  debugEcho ' '.repeat(tabs), $node
  if not node.isLeaf:
    for child in node.children:
      printRoutingTree(child, tabs + 1)

func printRoutingTree*(router: Router) =
  ## Prints the route.
  for httpMethod, tree in pairs(router.data):
    debugEcho httpMethod.toUpper
    printRoutingTree(tree)

func newRouter*(): Router {.inline.} =
  ## Creates a new ``Router`` instance.
  result = Router(data: CritBitTree[PatternNode]())

template isInvalidPath(path: string): bool =
  path.allCharsInSet(allowedCharsInPattern)

func ensureCorrectRoute(
  path: string
): string {.raises: [].} =
  ## Strips trailing slashes, and guarantees one leading slash.
  pathSeparator & path.strip(chars={pathSeparator})

func emptyBnodeSequence(
  bnodeSeq: seq[BasePatternNode]
): bool {.inline.} =
  ## A bnode sequence is empty if it A) contains no elements or B) 
  ## it contains a single text element with no value.
  result = (bnodeSeq.len == 0 or (bnodeSeq.len == 1 and bnodeSeq[0].kind ==
              ptrnText and bnodeSeq[0].value == ""))

func generateRope(
  pattern: string,
  startIndex = 0
): seq[BasePatternNode] {.raises: [RouteError].} =
  ## Translates the string form of a pattern into a sequence of BasePatternNode objects to be parsed against.
  var token: string
  let tokenSize = pattern.parseUntil(token, specialSectionStartChars, startIndex)
  var newStartIndex = startIndex + tokenSize

  if newStartIndex < pattern.len: # we encountered a wildcard or parameter def, there could be more left
    let specialChar = pattern[newStartIndex]
    inc newStartIndex

    var scanner: BasePatternNode

    if specialChar == wildcard:
      if newStartIndex < pattern.len and pattern[newStartIndex] == greedyIndicator:
        inc newStartIndex
        if pattern.len != newStartIndex:
          raise newException(RouteError, "$ found before end of route!")
        scanner = BasePatternNode(kind: ptrnWildcard, isGreedy: true)
      else:
        scanner = BasePatternNode(kind: ptrnWildcard)
    elif specialChar == startParam:
      var paramName: string
      let paramNameSize = pattern.parseUntil(paramName, endParam, newStartIndex)
      inc(newStartIndex, paramNameSize + 1)
      if pattern.len > newStartIndex and pattern[newStartIndex] == greedyIndicator:
        inc newStartIndex
        if pattern.len != newStartIndex:
          raise newException(RouteError, "$ found before end of route!")
        scanner = BasePatternNode(kind: ptrnParam, value: paramName, isGreedy: true)
      else:
        scanner = BasePatternNode(kind: ptrnParam, value: paramName)
    elif specialChar == pathSeparator:
      scanner = BasePatternNode(kind: ptrnText, value: ($pathSeparator))
    else:
      raise newException(RouteError, "Unrecognized special character!")

    var prefix: seq[BasePatternNode]
    if tokenSize > 0:
      prefix = @[BasePatternNode(kind: ptrnText, value: token), scanner]
    else:
      prefix = @[scanner]

    let suffix = generateRope(pattern, newStartIndex)

    if emptyBnodeSequence(suffix):
      result = prefix
    else:
      result = concat(prefix, suffix)

  else: #no more wildcards or parameter defs, the rest is static text
    result = newSeq[BasePatternNode](token.len)
    for i, c in pairs(token):
      result[i] = BasePatternNode(kind: ptrnText, value: ($c))

func terminatingPatternNode(
  oldNode: PatternNode,
  bnode: BasePatternNode,
  handler: PathHandler,
  route: string
): PatternNode {.raises: [RouteError].} =
  ## Turns the given node into a terminating node ending at the given bnode/handler pair. 
  ## If it is already a terminator, throws an exception.
  if oldNode.isTerminator: # Already mapped
    raise newException(DuplicatedRouteError, "Duplicate route detected: " & route)
  case bnode.kind
  of ptrnText:
    result = PatternNode(kind: ptrnText, value: bnode.value,
        isLeaf: oldNode.isLeaf, isTerminator: true, handler: handler)
  of ptrnParam:
    result = PatternNode(kind: ptrnParam, value: bnode.value,
        isLeaf: oldNode.isLeaf, isTerminator: true, handler: handler,
        isGreedy: bnode.isGreedy)
  of ptrnWildcard:
    result = PatternNode(kind: ptrnWildcard, isLeaf: oldNode.isLeaf,
        isTerminator: true, handler: handler, isGreedy: bnode.isGreedy)

  result.handler = handler

  if not result.isLeaf:
    result.children = oldNode.children

func parentalPatternNode(oldNode: PatternNode): PatternNode =
  ## Turns the given node into a parent node. If it not a leaf node, this returns a new copy of the input.
  case oldNode.kind
  of ptrnText:
    result = PatternNode(kind: ptrnText, value: oldNode.value,
                         isLeaf: false, children: newSeq[PatternNode](),
                         isTerminator: oldNode.isTerminator)
  of ptrnParam:
    result = PatternNode(kind: ptrnParam, value: oldNode.value,
                         isLeaf: false, children: newSeq[PatternNode](),
                         isTerminator: oldNode.isTerminator, isGreedy: oldNode.isGreedy)
  of ptrnWildcard:
    result = PatternNode(kind: ptrnWildcard, isLeaf: false,
                         children: newSeq[PatternNode](),
                         isTerminator: oldNode.isTerminator, isGreedy: oldNode.isGreedy)

  if result.isTerminator:
    result.handler = oldNode.handler

func indexOf(nodes: seq[PatternNode], bnode: BasePatternNode): int {.inline.} =
  ## Finds the index of nodes that matches the given bnode. If none is found, returns -1.
  for index, child in pairs(nodes):
    if child == bnode:
      return index
  result = -1 #the 'not found' value

func chainTree(rope: seq[BasePatternNode], handler: PathHandler): PatternNode =
  ## Creates a tree made up of single-child nodes that matches the given rope. 
  ## The last node in the tree is a terminator with the given handler.

  let bnode = rope[0]
  let lastKnot = (rope.len == 1) #since this is a chain tree, the only leaf node is the terminator node, so they are mutually linked, if this is true then it is both

  case bnode.kind
  of ptrnText:
    result = PatternNode(kind: ptrnText, value: bnode.value,
        isLeaf: lastKnot, isTerminator: lastKnot)
  of ptrnParam:
    result = PatternNode(kind: ptrnParam, value: bnode.value,
        isLeaf: lastKnot, isTerminator: lastKnot, isGreedy: bnode.isGreedy)
  of ptrnWildcard:
    result = PatternNode(kind: ptrnWildcard, isLeaf: lastKnot,
        isTerminator: lastKnot, isGreedy: bnode.isGreedy)

  if lastKnot:
    result.handler = handler
  else:
    result.children = @[chainTree(rope[1 .. ^1], handler)] #continue the chain

func merge(
  node: PatternNode,
  rope: seq[BasePatternNode],
  handler: PathHandler,
  route: string
): PatternNode {.raises: [RouteError].} =
  ## Merges the given sequence of MapperKnots into the given tree as a new mapping. 
  ## This does not mutate the given node, instead it will return a new one.

  if rope.len == 1: # Terminating bnode reached, finish the merge
    result = terminatingPatternNode(node, rope[0], handler, route)
  else:
    let currentKnot = rope[0]
    let nextKnot = rope[1]
    let remainder = rope[1 .. ^1]

    assert node == currentKnot

    var childIndex = -1
    if node.isLeaf: # node isn't a parent yet, make it one to continue
      result = parentalPatternNode(node)
    else:
      result = node
      childIndex = node.children.indexOf(nextKnot)

    if childIndex == -1: # the next bnode doesn't map to a child of this node, needs to me directly translated into a deep tree (one branch per level)
      result.children.add(chainTree(remainder,
          handler)) # make a node containing everything remaining and inject it
    else:
      result.children[childIndex] = merge(result.children[childIndex],
          remainder, handler, route)

func contains(
  node: PatternNode,
  rope: seq[BasePatternNode]
): bool =
  ## Determines whether or not merging rope into node will create a mapping conflict.

  if rope.len == 0: 
    return

  let bnode = rope[0]

  # Is this node equal to the bnode?
  if node.kind == bnode.kind:
    if node.kind == ptrnText:
      result = (node.value == bnode.value)
    else:
      result = true
  else:
    if (node.kind == ptrnWildcard and bnode.kind == ptrnParam) or
        (node.kind == ptrnParam and bnode.kind == ptrnWildcard):
      result = true
    elif (node.kind == ptrnWildcard and bnode.kind == ptrnText) or
        (node.kind == ptrnParam and bnode.kind == ptrnText) or
        (node.kind == ptrnText and bnode.kind == ptrnParam) or
        (node.kind == ptrnText and bnode.kind == ptrnWildcard):
      when defined(logueRouteLoose):
        result = false
      else:
        result = true
    else:
      result = false

  if not node.isLeaf and result: # if the node has kids, is at least one?
    if node.children.len > 0:
      result = false # false until proven otherwise
      for child in node.children:
        if child.contains(rope[1 .. ^1]): # does the child match the rest of the rope?
          result = true
          break
  elif node.isLeaf and rope.len > 1: # the node is a leaf but we want to map further to it, so it won't conflict
    result = false

func newPathHandler*(handler: HandlerAsync, middlewares: seq[HandlerAsync]): PathHandler {.inline.} =
  PathHandler(handler: handler, middlewares: middlewares)

func addRoute*(
  router: Router,
  route: string,
  httpMethod: HttpMethod,
  handler: HandlerAsync,
  middlewares: seq[HandlerAsync]
) =
  ## Add a new mapping to the given ``Router`` instance.
  if not isInvalidPath(route):
    raise newException(RouteError, "Illegal characters occurred in the mapped pattern," &
                    "please restrict to alphanumeric, or the following: - . _ ~ / * { } & '")
  var rope = generateRope(ensureCorrectRoute(route))       # initialize rope
  let httpMethod = $httpMethod

  var nodeToBeMerged: PatternNode
  if router.data.hasKey(httpMethod):
    nodeToBeMerged = router.data[httpMethod]
    if nodeToBeMerged.contains(rope):
      raise newException(DuplicatedRouteError, "Duplicate route encountered: " & route)
  else:
    nodeToBeMerged = PatternNode(kind: ptrnText, value: $pathSeparator,
                                 isLeaf: true, isTerminator: false)

  router.data[httpMethod] = nodeToBeMerged.merge(rope, newPathHandler(handler, middlewares), route)

func compress(node: PatternNode): PatternNode =
  ## Finds sequences of single ptrnText nodes and combines them to reduce the depth of the tree.

  if node.isLeaf: # if it's a leaf, there are clearly no descendants, and if it is a terminator then compression will alter the behaviour.
    return node
  elif node.kind == ptrnText and (not node.isTerminator) and node.children.len == 1:
    let compressedChild = compress(node.children[0])
    if compressedChild.kind == ptrnText:
      result = compressedChild
      result.value = node.value & compressedChild.value
      return

  result = node
  result.children = map(result.children, compress)

func compress*(router: Router) =
  ## Compresses the entire contents of the given ``Router``. Successive calls will recompress, but may not be efficient, so use this only when mapping is complete for the best effect
  for index, existing in pairs(router.data):
    router.data[index] = compress(existing)

func matchTree(
  ctx: Context,
  head: PatternNode,
  path: string,
  pathIndex = 0,
): Option[PathHandler] =
  ## Check whether the given path matches the given tree node starting from pathIndex.

  var node = head
  var pathIndex = pathIndex

  block matching:
    while pathIndex >= 0:
      case node.kind
      of ptrnText:
        if path.continuesWith(node.value, pathIndex):
          inc(pathIndex, node.value.len)
        else:
          break matching
      of ptrnWildcard:
        if node.isGreedy:
          pathIndex = path.len
        else:
          pathIndex = path.find(pathSeparator,
                                pathIndex) # skip forward to the next separator
          if pathIndex == -1:
            pathIndex = path.len
      of ptrnParam:
        if node.isGreedy:
          ctx.request.pathParams[node.value] = path[pathIndex .. ^1]
          pathIndex = path.len
        else:
          let newPathIndex = path.find(pathSeparator,
                                       pathIndex) # skip forward to the next separator
          if newPathIndex == -1:
            ctx.request.pathParams[node.value] = path[pathIndex .. ^1]
            pathIndex = path.len
          else:
            ctx.request.pathParams[node.value] = path[pathIndex .. newPathIndex - 1]
            pathIndex = newPathIndex

      if pathIndex == path.len and node.isTerminator: # the path was exhausted and we reached a node that has a handler
        return some(node.handler)
       
      elif not node.isLeaf: # there is children remaining, could match against children
        if node.children.len == 1: # optimization for single child that just points the node forward
          node = node.children[0]
        else: # more than one child
          doAssert node.children.len != 0
          for child in node.children:
            result = ctx.matchTree(child, path, pathIndex)
            if result.isSome:
              return
          break matching # none of the children matched, assume no match
      else: # its a leaf and we haven't satisfied the path yet, let the last line handle returning
        break matching

func findHandler(
  ctx: Context, 
  reqMethod: string,
  path: string
): Option[PathHandler] {.inline.} =
  ## Find a mapping that matches the given request description.
  let reqMethod = reqMethod.toUpperAscii

  if ctx.gScope.router.data.hasKey(reqMethod):
    result = ctx.matchTree(ctx.gScope.router.data[reqMethod],
    ensureCorrectRoute(path))
  else:
    result = none(PathHandler)

func findHandler*(
    ctx: Context,
    reqMethod: HttpMethod,
    path: string
): Option[PathHandler] {.inline.} =
  ## Simple wrapper around the regular route function.
  findHandler(ctx, $reqMethod, path)

func stripRoute*(route: string): string {.inline.} =
  result = route
  # Don't strip single slash
  if result.len > 1:
    if result[^1] == '/':
      result.setLen(result.high)

func findHandler*(ctx: Context): PathHandler {.inline.} =
  ## fixed route -> params route -> regex route
  ## Follow the order of addition.
  
  # Notes path will be striped one slash.
  # Such as 
  # /hello/ -> /hello
  # /hello -> /hello
  # / -> /
  # let route = ctx.request.url.path.stripRoute
  let route = ctx.request.url.path
  let reqMethod = ctx.request.reqMethod

  if isInvalidPath(route):
    let handler = findHandler(ctx, reqMethod, route)
    if handler.isSome:
      return handler.get

  # find regex route
  for (path, pathHandler) in ctx.gScope.reRouter:
    if path.httpMethod != reqMethod:
      continue
    var m: RegexMatch

    if route.match(path.route, m):
      for name in groupNames(m):
        ctx.request.pathParams[name] = m.groupFirstCapture(name, route)
      return pathHandler

  # no find route
  result = PathHandler(handler: defaultHandler)
