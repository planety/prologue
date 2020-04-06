switch("path", "$projectDir/../src")
when (NimMajor, NimMinor) >= (1, 2):
  switch("gc", "arc")