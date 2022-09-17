# Basic example
A small example of a prologue application that demonstrates:
1. How to set up a simple route
2. One way to load settings
3. How to use middleware for static file serving
4. How to extend the context of a request with your own custom data (useful e.g. for adding login data to your context via middleware)

The binary that this example compiles to serves a response on `/` and also serves file of a directory `./static` (filepath relative to binary placement) as defined by `.env`.

### .env
A tiny config file

### app.nim
The main file of the project. 
It loads config values from a small `.env` file via [`loadPrologueEnv`](https://planety.github.io/prologue/configure/) to generate the settings of this application.

With the settings it then creates the prologue application `app`, which gets [middleware for static file serving](https://planety.github.io/prologue/middleware/) and [a route](https://planety.github.io/prologue/routing/) attached to it. 
After all that setup is done, the server is started.

### myctx.nim
Extends the `Context` of a request (which contains the request the user sent, settings of the server and more) by a single field called `id`.

### urls.nim
Simply associates urls (`"/"`) with procs to call when a HTTP request for that url arrives (`hello`).

This is done in `urls.nim` instead of `views.nim` as an example of how you can structure a prologue application with a clean separation of concerns. This way, the `views` module is only concerned with creating procs that can handle HTTP requests, while the `urls` module is only concerned with mapping which proc should be used when a specific URL gets called.

The `hello` proc stems from the `views.nim` module

### views.nim
Simply defines a controller/handler proc called `hello` to deal with an incoming HTTP request.

It makes use of the context that was extended to `DataContext` to echo out the newly defined id field.

