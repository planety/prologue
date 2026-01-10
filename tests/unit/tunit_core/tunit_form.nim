import ../../../src/prologue/core/form
import tables, strutils, strtabs

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

block:
  # Test for file input field (issue: multipart/form-data not working)
  # This tests that file inputs with filename parameter work correctly
  const testmime =
    "------WebKitFormBoundary7MA4YWxkTrZu0gW\13\10" &
    "Content-Disposition: form-data; name=\"myfile\"; filename=\"test.txt\"\13\10" &
    "Content-Type: text/plain\13\10" &
    "\13\10" &
    "Hello World\13\10" &
    "------WebKitFormBoundary7MA4YWxkTrZu0gW--\13\10"
  const contenttype = "multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW"
  let formPart = parseFormPart(testmime, contenttype)
  doAssert formPart.data.contains("myfile"), "myfile field should be present"
  doAssert formPart.data["myfile"].body == "Hello World"
  doAssert formPart.data["myfile"].params.getOrDefault("filename", "") == "test.txt"

block:
  # Test for multiple file inputs with the same name (issue: handle multiple file upload from a single input element)
  # This tests that multiple files uploaded with the same input name are all captured
  const testmime =
    "------WebKitFormBoundary7MA4YWxkTrZu0gW\13\10" &
    "Content-Disposition: form-data; name=\"files\"; filename=\"test1.txt\"\13\10" &
    "Content-Type: text/plain\13\10" &
    "\13\10" &
    "First file content\13\10" &
    "------WebKitFormBoundary7MA4YWxkTrZu0gW\13\10" &
    "Content-Disposition: form-data; name=\"files\"; filename=\"test2.txt\"\13\10" &
    "Content-Type: text/plain\13\10" &
    "\13\10" &
    "Second file content\13\10" &
    "------WebKitFormBoundary7MA4YWxkTrZu0gW\13\10" &
    "Content-Disposition: form-data; name=\"files\"; filename=\"test3.txt\"\13\10" &
    "Content-Type: text/plain\13\10" &
    "\13\10" &
    "Third file content\13\10" &
    "------WebKitFormBoundary7MA4YWxkTrZu0gW--\13\10"
  const contenttype = "multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW"
  let formPart = parseFormPart(testmime, contenttype)
  
  # Verify that all three files with the same name are captured
  doAssert formPart.data.contains("files"), "files field should be present"
  doAssert formPart.data["files"].len == 3, "Should have 3 files"
  
  # Verify first file
  doAssert formPart.data["files"][0].body == "First file content"
  doAssert formPart.data["files"][0].params.getOrDefault("filename", "") == "test1.txt"
  doAssert formPart.data["files"][0].params.getOrDefault("Content-Type", "") == "text/plain"
  
  # Verify second file
  doAssert formPart.data["files"][1].body == "Second file content"
  doAssert formPart.data["files"][1].params.getOrDefault("filename", "") == "test2.txt"
  doAssert formPart.data["files"][1].params.getOrDefault("Content-Type", "") == "text/plain"
  
  # Verify third file
  doAssert formPart.data["files"][2].body == "Third file content"
  doAssert formPart.data["files"][2].params.getOrDefault("filename", "") == "test3.txt"
  doAssert formPart.data["files"][2].params.getOrDefault("Content-Type", "") == "text/plain"
