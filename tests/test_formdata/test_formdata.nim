import ../../src/prologue/core/form
import tables, strutils, base64
let testfile = open("tests/test_formdata/testfile.txt", fmRead).readAll()
let testmime = open("tests/test_formdata/testmime.base64", fmRead).readAll().decode()
let contenttype = "multipart/form-data; boundary=---------------------------203238422770489380538321896"
let formPart = parseFormPart(testmime, contenttype)
doAssert formPart.data["upload"].body.len == testfile.len
doAssert formPart.data["upload"].body == testfile
doAssert parseInt(formPart.data["howLongValid"].body) == 3600