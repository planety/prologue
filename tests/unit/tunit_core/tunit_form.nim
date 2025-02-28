import ../../../src/prologue/core/form
import tables, strutils

block:
  const testmime =
    "-----------------------------263701891623491983764541468\13\10" &
    "Content-Disposition: form-data; name=\"howLongValid\"\13\10" &
    "\13\10" &
    "3600\13\10" &
    "-----------------------------263701891623491983764541468\13\10" &
    "Content-Disposition: form-data; name=\"upload\"; filename=\"testfile.txt\"\13\10" &
    "Content-Type: text/plain\13\10" &
    "\13\10" &
    "1234\13\10" &
    "5678\13\10" &
    "abcd\13\10" &
    "-----------------------------263701891623491983764541468--\13\10"
  const testfile =
    "1234\13\10" &
    "5678\13\10" &
    "abcd"
  const contenttype = "multipart/form-data; boundary=---------------------------263701891623491983764541468"
  let formPart = parseFormPart(testmime, contenttype)
  doAssert formPart.data["upload"].body.len == testfile.len
  doAssert formPart.data["upload"].body == testfile
  doAssert parseInt(formPart.data["howLongValid"].body) == 3600

block:
  # check that quoted boundary values work
  const testfile =
    "data"
  const testmime =
    "--boundary\13\10" &
    "Content-Disposition: form-data; name=\"upload\"\13\10" &
    "\13\10" &
    testfile &
    "\13\10" &
    "--boundary--\13\10"
  const contenttype = "multipart/form-data; boundary=\"boundary\""
  let formPart = parseFormPart(testmime, contenttype)
  doAssert formPart.data["upload"].body.len == testfile.len
  doAssert formPart.data["upload"].body == testfile
