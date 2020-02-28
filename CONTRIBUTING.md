### prefer `len` to `default` 
switch to `isDefault` when this pr is accepted.

https://github.com/nim-lang/Nim/pull/13526
```nim
# use len
let 
  a = ""
  b = @[]

assert a.len != 0
assert b.len != 0

# don't use
assert a != ""
assert b != ""
```
