from ../core/types import SecretKey


type
  User* = object of RootObj
    username: string
    password: SecretKey
    email: string
    firstName, lastName: string

  SuperUser* = object of User

func initUser*(username: string, password: SecretKey, email, firstName,
    lastName = ""): User {.inline.} =
  User(username: username, password: password, email: email,
      firstName: firstName, lastName: lastName)
