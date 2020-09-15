import redis, asyncdispatch

proc main() {.async.} =
  ## Open a connection to Redis running on localhost on the default port (6379)
  let redisClient = await openAsync()

  ## Set the key `nim_redis:test` to the value `Hello, World`
  await redisClient.setk("nim_redis:test", "Hello, World")

  ## Get the value of the key `nim_redis:test`
  let value = await redisClient.get("nim_redis:test")

  assert(value == "Hello, World")

waitFor main()
