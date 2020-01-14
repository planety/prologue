import htmlgen

proc error*(errorMsg, version: string): string =
  return html(head(title(errorMsg)),
              body(h1(errorMsg),
                   "<hr/>",
                   p("Prologue " & version),
                   style = "text-align: center;"
              ),
              xmlns="http://www.w3.org/1999/xhtml")
