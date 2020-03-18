from ../core/types import SecretKey


type
  User* = ref object of RootObj
    username: string
    password: SecretKey
    email: string
    firstName, lastName: string

  SuperUser* = ref object of User

proc initUser*(username: string, password: SecretKey, email, firstName,
    lastName = ""): User =
  User(username: username, password: password, email: email,
      firstName: firstName, lastName: lastName)
