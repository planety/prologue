import ../../src/prologue

import ./urls


var app = newAppQueryEnv()
# Be careful with the routes.
app.addRoute(urls.urlPatterns, "")
app.run()
