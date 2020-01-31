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
  License* = object
    name*, url*: string
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
  Schema* = object
    schemaType: string
    title: string
    multipleOf: string
    maximum: string
    exclusiveMaximum: string
    minimum: string
    exclusiveMinimum: string
    maxLength: string
    minLength: string
    pattern: string
    maxItems: string
    minItems: string
    uniqueItems: string
    maxProperties: string
    minProperties: string
    required: string
    shemaEnum: string

proc initContact*(name, url, email = ""): Contact =
  Contact(name: name, url: url, email: email)

proc `$`*(contact: Contact): string =
  $ %* contact

proc initLicense*(name: string, url = ""): License =
  License(name: name, url: url)

proc `$`*(license: License): string =
  $ %* license

proc initInfo*(title, licenseName, version: string; description, termsOfService = ""; contactName, contactUrl, contactEmail = "";
     licenseUrl = ""): Info =
  Info(title: title, description: description, termsOfService: termsOfService,
      contact: initContact(contactName, contactUrl, contactEmail),
          license: initLicense(licenseName, licenseUrl), version: version)

proc `$`*(info: Info): string =
  $ %* {
    "title": info.title,
    "description": info.description,
    "termsOfService": info.termsOfService,
    "contact": info.contact,
    "license": info.license,
    "version": info.version
  }

proc writeDocs*(description: string; fileName = "openapi.json"; dirs = "docs") =
  if not existsDir(dirs):
    createDir(dirs)
  let f = open(dirs / fileName, fmWrite)
  defer: f.close()
  f.write(description)
