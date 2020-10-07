## Compilation options

```bash
nim c -r --d:release --threads:on b_*.nim
```

## Benchmark
Benchmark with `wrk`:

```bash
curl http://localhost:8080/hello && echo "\n" && ./wrk -t15 -c250 -d5s http://localhost:8080/hello
```
