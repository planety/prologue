import ../../src/prologue


import views, urls

let settings = newSettings(appName = "StarLight")
var app = initApp(settings = settings, middlewares = @[])
app.addRoute(urls.urlPatterns, "/todolist")
app.addRoute("/", home, HttpGet)
app.addRoute("/", home, HttpPost)
app.addRoute("/index.html", index, HttpGet)
app.addRoute("/prefix/home", home, HttpGet)
app.addRoute("/home", home, HttpGet)
app.addRoute("/hello", hello, HttpGet)
app.addRoute("/redirect", testRedirect, HttpGet)
app.addRoute("/login", login, HttpGet)
app.addRoute("/login", do_login, HttpPost)
app.addRoute("/hello/{name}", helloName, HttpGet)
app.addRoute("/multipart", multiPart, HttpGet)
app.addRoute("/multipart", do_multiPart, HttpPost)
app.run()
