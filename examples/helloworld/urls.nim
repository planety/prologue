import views


let urlPatterns = @[
  ("/", home, HttpGet),
  ("/", home, HttpPost),
  ("/home", home, HttpGet)
]