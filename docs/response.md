# Response

## Respond by types

You can specify different responses by types.
- htmlResponse -> HTML format
- plainTextResponse -> Plain Text format
- jsonResponse -> Json format

## Respond by error code
- error404 -> return 404
- redirect -> return 301 and redirect to a new page
- abort -> return 401

## Other utils

You can set the cookie and header of the response.

`SetCookie`: sets the cookie of the response.
`DeleteCookie`: deletes the cookie of the response.
`setHeader`: sets the header values of the response.
`addHeader`: adds header values to the existing `HttpHeaders`.
