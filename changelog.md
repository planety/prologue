## 0.3.2

Fixes `resp "Hello"` will clear all attributes.

Reduces unnecessary operations.

Adds tests for cookie.

Reduces unnecessary imports and compilation time.

## 0.3.0

Windows support multi-thread HTTP server(httpx).

The route of the request is stripped. (/hello/ -> /hello)

## 0.2.8

Adds `Settings.address`, user can specify listening `address`.

Openapi docs allows specifying source path.

Fix `configure.getOrdefault`'s bug.

Adds more documents.

Adds more API docs.

Changes import path, allows `import prologue/middlewares` instead of 
`import prologue/middlewares/middlewares`. 

Renames `validate` to `validater`. Supports `import prologue/auth`, `import prologue/auth`, `import prologue/middlewares`, `import prologue/openapi`, `import prologue/security`, `import prologue/signing` and `import prologue/validater`.

Moves signing from the core directory.
