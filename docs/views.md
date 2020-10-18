# Views

`Prologue` doesn't provide any templates engines. But we recommend [karax](https://github.com/pragmagic/karax) to you. `karax` is a powerful template engines based on DSL. It is suitable for server side rendering.

You should use `nimble install karax` or `logue extension karax` to install it.

```nim
import karax / [karaxdsl, vdom]

const frameworks = ["Prologue", "Httpx", "Starlight"]


proc render*(L: openarray[string]): string =
  let vnode = buildHtml(tdiv(class = "mt-3")):
    h1: text "Which is my favourite web framework?"
    p: text "echo Prologue"

    ul:
      for item in L:
        li: text item
    dl:
      dt: text "Is Prologue an elegant web framework?"
      dd: text "Yes"
  result = $vnode

echo render(frameworks)
```
