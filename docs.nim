import os


removeFile("docs/coreapi/dochack.js")
removeFile("docs/plugin/dochack.js")
copyFile("dochack/dochack.js", "docs/coreapi/dochack.js")
copyFile("dochack/dochack.js", "docs/plugin/dochack.js")
