# openapi

`Prologue` supplies minimal supports for `openapi` docs. You need to write `openapi.json` by yourself. Then `Prologue` will register corresponding routes.

```nim
import prologue
import prologue/openapi


app.serveDocs("docs/openapi.json")
app.run()
```

[example](https://github.com/planety/prologue/blob/devel/examples/helloworld/docs/openapi.json) for `docs/openapi.json`.

visit `localhost:8080/docs` or `localhost:8080/redocs`

![hello world](assets/openapi/docs.jpg)
