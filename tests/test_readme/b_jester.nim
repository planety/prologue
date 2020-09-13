import jester

settings:
  port = Port(8080)

routes:
  get "/hello":
    resp "Hello, jester!"
