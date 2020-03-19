# Response

Response object

```nim
type
  Response* = object
    httpVersion*: HttpVersion
    code*: HttpCode
    httpHeaders*: HttpHeaders
    body*: string
```