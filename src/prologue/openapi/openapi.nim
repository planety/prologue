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

import std/[json, strtabs, asyncdispatch]

from ../core/application import Prologue, addRoute, appDebug
from ../core/response import htmlResponse, resp, jsonResponse
from ../core/context import Context, staticFileResponse, gScope
from ../core/request import setHeader


const
  swaggerDocs* = """<!DOCTYPE html>
  <html>
  
  <head>
    <link type="text/css" rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@3/swagger-ui.css">
    <link rel="shortcut icon">
    <title>Prologue API - Swagger UI</title>
  </head>
  
  <body>
    <div id="swagger-ui">
    </div>
    <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@3/swagger-ui-bundle.js"></script>
    <!-- `SwaggerUIBundle` is now available on the page -->
    <script>
      const ui = SwaggerUIBundle({
        url: '/openapi.json',
        oauth2RedirectUrl: window.location.origin + '/docs/oauth2-redirect',
        dom_id: '#swagger-ui',
        presets: [
          SwaggerUIBundle.presets.apis,
          SwaggerUIBundle.SwaggerUIStandalonePreset
        ],
        layout: "BaseLayout",
        deepLinking: true
      })
    </script>
  </body>
  
  </html>
"""

  redocs* = """<!DOCTYPE html>
  <html>
    <head>
      <title>ReDoc</title>
      <!-- needed for adaptive design -->
      <meta charset="utf-8"/>
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <link href="https://fonts.googleapis.com/css?family=Montserrat:300,400,700|Roboto:300,400,700" rel="stylesheet">
  
      <!--
      ReDoc doesn't change outer page styles
      -->
      <style>
        body {
          margin: 0;
          padding: 0;
        }
      </style>
    </head>
    <body>
      <redoc spec-url='/openapi.json'></redoc>
      <script src="https://cdn.jsdelivr.net/npm/redoc@next/bundles/redoc.standalone.js"> </script>
    </body>
  </html> 
"""

proc openapiHandler*(ctx: Context) {.async.} =
  resp jsonResponse(parseJson(readFile(ctx.gScope.appData["openApiDocsPath"])))

proc swaggerHandler*(ctx: Context) {.async.} =
  resp htmlResponse(swaggerDocs)

proc redocsHandler*(ctx: Context) {.async.} =
  resp htmlResponse(redocs)

proc serveDocs*(app: Prologue, source: string, onlyDebug = false) {.inline.} =
  if onlyDebug and not app.appDebug:
    return
  app.gScope.appData["openApiDocsPath"] = source
  app.addRoute("/openapi.json", openapiHandler)
  app.addRoute("/docs", swaggerHandler)
  app.addRoute("/redocs", redocsHandler)
