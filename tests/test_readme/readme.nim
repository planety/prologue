import osproc, strformat


# Test Examples
block:
  let
    e1 = "tests/test_readme/example1.nim"
    e2 = "tests/test_readme/example2.nim"
    e3 = "tests/test_readme/example3.nim"
    execCommand = "nim c --gc:arc --d:release --hints:off"

  # example1 can compile
  block:
    let (outp, errC) = execCmdEx(fmt"{execCommand} {e1}")
    doAssert errC == 0, outp

  # example2 can compile
  block:
    let (outp, errC) = execCmdEx(fmt"{execCommand} {e2}")
    doAssert errC == 0, outp
    
  # example3 can compile
  block:
    let (outp, errC) = execCmdEx(fmt"{execCommand} {e3}")
    doAssert errC == 0, outp
  
