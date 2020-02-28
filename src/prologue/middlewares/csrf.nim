from ../core/urandom import randomString, DefaultEntropy

from htmlgen import input


proc newCSRFToken*(size = DefaultEntropy): string =
  input(`type`="hidden", name="CSRFToken", value = randomString(size))
