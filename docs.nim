import os


removeFile("docs/coreapi/dochack.js")
removeFile("docs/plugin/dochack.js")
copyFile("docs/dochack.js", "docs/coreapi/dochack.js")
copyFile("docs/dochack.js", "docs/plugin/dochack.js")
