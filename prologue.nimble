# Package

version       = "0.6.4"
author        = "ringabout"
description   = "Prologue is an elegant and high performance web framework"
license       = "Apache-2.0"
srcDir        = "src"


# Dependencies
requires "nim >= 1.6.0"
requires "regex >= 0.20.0"
requires "nimcrypto >= 0.5.4"
requires "cookiejar >= 0.2.0"
requires "httpx >= 0.3.4"
requires "logue >= 0.2.0"


# tests
task tests, "Run all tests":
  exec "testament all"

task tstdbackend, "Test asynchttpserver backend":
  exec "nim c -r -d:release -d:usestd tests/server/tserver_application.nim"

task texamples, "Test examples":
  exec "nim c -d:release tests/compile/test_examples/examples.nim"
  exec "nim c -d:release -d:usestd tests/compile/test_examples/examples.nim"

task treadme, "Test Readme":
  exec "nim c -d:release tests/compile/test_readme/readme.nim"

task tcompile, "Test Compile":
  exec "nim c -r -d:release tests/compile/test_compile/test_compile.nim"

task docs, "Only for gh-pages, not for users":
  exec "mkdocs build"
  exec "mkdocs gh-deploy"

task apis, "Only for api":
  exec "nim doc --verbosity:0 --warnings:off --project --index:on " &
    "--git.url:https://github.com/planety/prologue " &
    "--git.commit:devel " &
    "-o:docs/coreapi " &
    "src/prologue/core/application.nim"

  exec "nim buildIndex -o:docs/coreapi/theindex.html docs/coreapi"

  exec "nim doc --verbosity:0 --warnings:off --project --index:on " &
    "--git.url:https://github.com/planety/prologue " &
    "--git.commit:devel " &
    "-o:docs/plugin " &
    "src/prologue/plugin.nim"

  exec "nim buildIndex -o:docs/plugin/theindex.html docs/plugin"

task redis, "Install redis":
  exec "nimble install redis@#c02d404 -y"

task karax, "Install karax":
  exec """nimble install karax@">= 1.1.2" -y"""

task websocketx, "Install websocketx":
  exec """nimble install websocketx@">= 0.1.2" -y"""

task extension, "Install all extensions":
  exec "nimble redis"
  exec "nimble karax"
  exec "nimble websocketx"
