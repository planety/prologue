import asyncdispatch, httpcore

from ../core/context import Context, setHeader
from ../core/response import htmlResponse, resp


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
  let text = readFile("docs/openapi.json")
  ctx.response.body = text
  ctx.response.status = Http200
  ctx.setHeader("Content-Type", "text/json")

proc swaggerHandler*(ctx: Context) {.async.} =
  resp htmlResponse(swaggerDocs)

proc redocsHandler*(ctx: Context) {.async.} =
  resp htmlResponse(redocs)
  