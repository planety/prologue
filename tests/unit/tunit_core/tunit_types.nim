import ../../../src/prologue/core/types

import std/[strtabs, options]


# "Test Parse Utils"
block:
  # "can parse int"
  block:
    doAssert parseValue("12", 3) == 12
    doAssert parseValue("x", 1) == 1

  # "can parse float"
  block:
    doAssert parseValue("12.5", 3.4) == 12.5
    doAssert parseValue("z", 1.4) == 1.4

  # "can parse bool"
  block:
    doAssert parseValue("true", true)
    doAssert not parseValue("s", false)

  # "can parse string"
  block:
    doAssert parseValue("fight", "") == "fight"


# "Test Secret Key"
block:
  # "can hide secret key"
  block:
    let secretKey = SecretKey("PrologueSecretKey")
    doAssert $secretKey == "SecretKey(********)"

  # "can expose secret key"
  block:
    let secretKey = SecretKey("PrologueSecretKey")
    doAssert string(secretKey) == "PrologueSecretKey"


# "Deserialize StringTable"
block:
  # "can parse stringTable from empty stringTable"
  block:
    let tabs = newStringTable(mode = modeCaseSensitive)
    var newTabs = newStringTable(mode = modeCaseSensitive)
    parseStringTable(newTabs, $tabs)
    doAssert $newTabs == $tabs

  # "can parse stringTable from stringTable with elements"
  block:
    let tabs = {"username": "flywind", "password": "root"}.newStringTable()
    var newTabs = newStringTable(mode = modeCaseSensitive)
    parseStringTable(newTabs, $tabs)
    doAssert $newTabs == $tabs

  # "can parse stringTable from stringTable with empty value"
  block:
    let tabs = {"username": "flywind", "password": "",
        "day": "one"}.newStringTable()
    var newTabs = newStringTable(mode = modeCaseSensitive)
    parseStringTable(newTabs, $tabs)
    doAssert $newTabs == $tabs

  # "can parse stringTable from stringTable with empty key"
  block:
    let tabs = {"username": "flywind", "password": "root",
        "": "one"}.newStringTable()
    var newTabs = newStringTable(mode = modeCaseSensitive)
    parseStringTable(newTabs, $tabs)
    doAssert $newTabs == $tabs

  # "can parse stringTable from stringTable with space key or value"
  block:
    let tabs = {"user    name": "   flywind", "password": " ro  ot  ",
        "": "    o ne"}.newStringTable()
    var newTabs = newStringTable(mode = modeCaseSensitive)
    parseStringTable(newTabs, $tabs)
    doAssert $newTabs == $tabs

block:
  doAssert $Info == "info"
  doAssert $Warning == "warning"
  doAssert $Error == "error"
  doAssert $Fault == "fault"

# session
block:
  block:
    var session = newSession(newStringTable())
    session.flash("Hello, world")

    doAssert session.accessed
    doAssert session.modified
    doAssert session.len == 1

    doAssert session.messages == @["Hello, world"]
    doAssert session.messages == @[]

    session.flash("Hello, world")
    doAssert session.messagesWithCategory == @[("info", "Hello, world")]
    session.flash("Hello, world")
    doAssert getMessage(session, FlashLevel.Info).get == "Hello, world"
    session.flash("Hello, world")
    doAssert getMessage(session, "info").get == "Hello, world"

  block:
    var session = newSession(newStringTable())
    session.flash("Hello, world", "custom")

    doAssert session.accessed
    doAssert session.modified
    doAssert session.len == 1

    doAssert session.messages == @["Hello, world"]

    session.flash("Hello, world", "custom")
    doAssert session.messagesWithCategory == @[("custom", "Hello, world")]

    session.flash("Hello, world", "custom")
    doAssert getMessage(session, "custom").get == "Hello, world"

  block:
    var session = newSession(newStringTable())
    session.flash("Hello, world", FlashLevel.Info)
    session.flash("We Love Prologue Framework", FlashLevel.Error)


    doAssert session.accessed
    doAssert session.modified
    doAssert session.len == 2

    doAssert session.messages == @["Hello, world", "We Love Prologue Framework"]

    session.flash("Hello, world", FlashLevel.Info)
    session.flash("We Love Prologue Framework", FlashLevel.Error)
    doAssert session.messagesWithCategory == @[("info", "Hello, world"), 
                                                      ("error", "We Love Prologue Framework")]
    
    session.flash("Hello, world", FlashLevel.Info)
    session.flash("We Love Prologue Framework", FlashLevel.Error)
    doAssert getMessage(session, "error").get == "We Love Prologue Framework"

  block:
    var session = newSession(newStringTable())
    session.flash("Hello, world", FlashLevel.Error)
    session.flash("We Love Prologue Framework", FlashLevel.Error)


    doAssert session.accessed
    doAssert session.modified
    doAssert session.len == 1

    doAssert session.messages == @["We Love Prologue Framework"]

    session.flash("Hello, world", FlashLevel.Error)
    session.flash("We Love Prologue Framework", FlashLevel.Error)
    doAssert session.messagesWithCategory == @[("error", "We Love Prologue Framework")]

    session.flash("Hello, world", FlashLevel.Error)
    session.flash("We Love Prologue Framework", FlashLevel.Error)
    doAssert getMessage(session, "error").get == "We Love Prologue Framework"
