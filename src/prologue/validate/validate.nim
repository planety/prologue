type
  ValidateHandler* = proc(text: string): bool {.closure.}


proc required*(): ValidateHandler =
  result = proc(text: string): bool =
    text.len != 0
