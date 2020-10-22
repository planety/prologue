import prologue

import ./urls


var app = newAppQueryEnv()
app.addRoute(urls.urlPatterns, "")
app.run()
