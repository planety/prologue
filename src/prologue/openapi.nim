import os, json

export json


type
  OpenApi* = object
    version*: string
    info*: Info
    servers*: seq[Servers]
    paths*: Paths
    components*: Components
    security*: Security
    tags*: Tags
    externalDocs*: ExternalDocs
  Info* = object
    title*: string
    description*: string
    termsOfService*: string
    contact*: Contact
    license*: License
    version*: string
  Contact = object
    name, url, email: string
  License = object
    name, url: string
  Servers = object
    url, description: string
    # variables: Variable
  # Variable = object
  #   enum: seq[string]
  Paths = object
  Components = object
  Security = object
  Tags = object
  ExternalDocs = object

proc initContact*(name, url, email: string): Contact =
  Contact(name: name, url: url, email: email)

proc initLicense*(name, url: string): License =
  License(name: name, url: url)

proc initInfo*(title, description, termsOfService: string; contact: Contact;
    license: License; version: string): Info =
  Info(title: title, description: description, termsOfService: termsOfService,
      contact: contact, license: license, version: version)


proc writeDocs*(description: string; fileName = "openapi.json"; dirs = "docs") =
  if not existsDir(dirs):
    createDir(dirs)
  let f = open(dirs / fileName, fmWrite)
  defer: f.close()
  f.write(description)

