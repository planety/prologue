import strtabs, redis, asyncdispatch


type
  Storage* = ref object of RootObj
  TableStorage* = ref object of Storage
    data: StringTableRef

  AsyncRedisStorage* = ref object of Storage
    data: AsyncRedis

    


method put(s: Storage, key, value: string) {.base, async.} = discard
method get(s: Storage, key: string): Future[string] {.base, async.} = discard


method put*(s: TableStorage, key, value: string) {.async.} =
  s.data[key] = value

method get*(s: TableStorage, key: string): Future[string] {.async.} =
  result = s.data[key]


method put*(s: AsyncRedisStorage, key, value: string) {.async.} =
  await s.data.setk(key, value)

method get*(s: AsyncRedisStorage, key: string): Future[string] {.async.} =
  result = await s.data.get(key)
