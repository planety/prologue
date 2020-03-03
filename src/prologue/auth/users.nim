from ../core/types import SecretKey


type
  User* = ref object of RootObj
    userName: string
    password: SecretKey
    email: string
    firstName, lastName: string

  SuperUser* = ref object of User

proc initUser*(userName: string, password: SecretKey, email, firstName,
    lastName = ""): User =
  User(userName: userName, password: password, email: email,
      firstName: firstName, lastName: lastName)
