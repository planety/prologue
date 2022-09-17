# Prologue Configuration example
A small example of a prologue application that demonstrates:
1. How to set up a simple route
2. How to change the config file loaded based on the `PROLOGUE` environmental variable

### app.nim file
The main file of the project. 
It loads the settings from a file in the `.config` directory. [Which specific config file from there is loaded depends on the `PROLOGUE` environment variable](https://planety.github.io/prologue/configure/#Changing-config-file-via-environment-variable). 

With the settings it then creates the prologue application `app`, which gets [a route](https://planety.github.io/prologue/routing/) attached to it. 
After all that setup is done, the server is started.

### urls.nim file
Simply associates urls (`"/"`) with procs to call when a HTTP request for that url arrives (`hello`).

This is done in `urls.nim` instead of `views.nim` as an example of how you can structure a prologue application with a clean separation of concerns. This way, the `views` module is only concerned with creating procs that can handle HTTP requests, while the `urls` module is only concerned with mapping which proc should be used when a specific URL gets called.

The `hello` proc stems from the `views.nim` module

### views.nim file
Simply defines a controller/handler proc called `hello` to deal with an incoming HTTP request.

## Compile and run project
Simply call `nim compile --run app.nim` while in this directory and access 127.0.0.1:8080 URL in your browser.