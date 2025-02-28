import ../../../src/prologue/core/contenttype
import std/[tables, strutils, strformat]

block:
  let mediaType = parseContentType("text/plain")
  doAssert mediaType.mainType == "text"
  doAssert mediaType.subType == "plain"
  doAssert mediaType.parameters.len == 0

block:
  let mediaType = parseContentType("text/plain; charset=utf-8")
  doAssert mediaType.mainType == "text"
  doAssert mediaType.subType == "plain"
  doAssert mediaType.parameters.len == 1
  doAssert "charset" in mediaType.parameters
  doAssert mediaType.parameters["charset"] == "utf-8"

block:
  let mediaType = parseContentType("text/plain; charset=utf-8; format=flowed")
  doAssert mediaType.mainType == "text"
  doAssert mediaType.subType == "plain"
  doAssert mediaType.parameters.len == 2
  doAssert "charset" in mediaType.parameters
  doAssert "format" in mediaType.parameters
  doAssert mediaType.parameters["charset"] == "utf-8"
  doAssert mediaType.parameters["format"] == "flowed"

block:
  let mediaType = parseContentType("text/plain; charset=\"utf-8\"")
  doAssert mediaType.mainType == "text"
  doAssert mediaType.subType == "plain"
  doAssert mediaType.parameters.len == 1
  doAssert "charset" in mediaType.parameters
  doAssert mediaType.parameters["charset"] == "utf-8"

block:
  let mediaType = parseContentType("application/json; charset=\"utf 8\"")
  doAssert mediaType.mainType == "application"
  doAssert mediaType.subType == "json"
  doAssert mediaType.parameters.len == 1
  doAssert "charset" in mediaType.parameters
  doAssert mediaType.parameters["charset"] == "utf 8"

block:
  let mediaType = parseContentType("multipart/form-data; boundary=---------------------------263701891623491983764541468")
  doAssert mediaType.mainType == "multipart"
  doAssert mediaType.subType == "form-data"
  doAssert mediaType.parameters.len == 1
  doAssert "boundary" in mediaType.parameters
  doAssert mediaType.parameters["boundary"] == "---------------------------263701891623491983764541468"

block:
  let mediaType = parseContentType("multipart/form-data; boundary=\"simple-boundary\"")
  doAssert mediaType.mainType == "multipart"
  doAssert mediaType.subType == "form-data"
  doAssert mediaType.parameters.len == 1
  doAssert "boundary" in mediaType.parameters
  doAssert mediaType.parameters["boundary"] == "simple-boundary"

block:
  let mediaType = parseContentType("multipart/form-data; boundary=\"boundary with spaces and-dashes\"")
  doAssert mediaType.mainType == "multipart"
  doAssert mediaType.subType == "form-data"
  doAssert mediaType.parameters.len == 1
  doAssert "boundary" in mediaType.parameters
  doAssert mediaType.parameters["boundary"] == "boundary with spaces and-dashes"

block:
  let mediaType = parseContentType("text/plain; description=\"This is a \\\"quoted\\\" description\"")
  doAssert mediaType.mainType == "text"
  doAssert mediaType.subType == "plain"
  doAssert mediaType.parameters.len == 1
  doAssert "description" in mediaType.parameters
  doAssert mediaType.parameters["description"] == "This is a \\\"quoted\\\" description"

block:
  let mediaType = parseContentType("TeXt/PlAiN; ChArSeT=UTF-8")
  doAssert mediaType.mainType == "text"
  doAssert mediaType.subType == "plain"
  doAssert mediaType.parameters.len == 1
  doAssert "charset" in mediaType.parameters
  doAssert mediaType.parameters["charset"] == "UTF-8"

block:
  let mediaType = parseContentType("  text/plain  ;  charset=utf-8  ;  format=flowed  ")
  doAssert mediaType.mainType == "text"
  doAssert mediaType.subType == "plain"
  doAssert mediaType.parameters.len == 2
  doAssert "charset" in mediaType.parameters
  doAssert "format" in mediaType.parameters
  doAssert mediaType.parameters["charset"] == "utf-8"
  doAssert mediaType.parameters["format"] == "flowed"

block:
  let mediaType = parseContentType("text/plain; charset")
  doAssert mediaType.mainType == "text"
  doAssert mediaType.subType == "plain"
  doAssert mediaType.parameters.len == 0

block:
  try:
    discard parseContentType("text")
    doAssert false, "Should have raised an exception"
  except ValueError:
    doAssert true

block:
  let mediaType = parseContentType("text/plain; charset=utf-8; format=flowed")
  let str = $mediaType
  doAssert str.startsWith("text/plain")
  doAssert "; charset=utf-8" in str
  doAssert "; format=flowed" in str

block:
  var mediaType = MediaType(
    mainType: "multipart",
    subType: "form-data",
    parameters: {"boundary": "simple boundary with spaces"}.toTable
  )
  let str = $mediaType
  doAssert str == "multipart/form-data; boundary=\"simple boundary with spaces\""

block:
  var mediaType = MediaType(
    mainType: "text",
    subType: "plain",
    parameters: {
      "charset": "utf-8",
      "description": "This is a description with spaces"
    }.toTable
  )
  let str = $mediaType
  doAssert str.startsWith("text/plain")
  doAssert "; charset=utf-8" in str
  doAssert "; description=\"This is a description with spaces\"" in str

# some real-world examples
block:
  let examples = [
    "text/html; charset=UTF-8",
    "application/json",
    "application/x-www-form-urlencoded",
    "multipart/form-data; boundary=something",
    "image/jpeg",
    "application/octet-stream",
    "text/css; charset=utf-8",
    "application/javascript",
    "multipart/mixed; boundary=\"frontier\"",
    "application/pdf",
    "text/plain; charset=us-ascii"
  ]

  for example in examples:
    let mediaType = parseContentType(example)
    let roundTrip = $mediaType

    let roundTripMediaType = parseContentType(roundTrip)
    doAssert roundTripMediaType.mainType == mediaType.mainType
    doAssert roundTripMediaType.subType == mediaType.subType
    doAssert roundTripMediaType.parameters.len == mediaType.parameters.len

    for key, value in mediaType.parameters:
      doAssert key in roundTripMediaType.parameters
      doAssert roundTripMediaType.parameters[key] == value
