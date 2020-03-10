import tables


type
  ValidateHandler* = proc(text: string): bool {.closure.}

  FormValidation* = object
    data: OrderedTableRef[string, seq[ValidateHandler]]


proc newFormValidation*(validator: openArray[(string, seq[ValidateHandler])]): FormValidation {.inline.} =
  FormValidation(data: validator.newOrderedTable)

# proc validate*(formValidation: FormValidation): bool =
#   for (key, handlers) in formValidation.data.pairs:

#     for handler in handlers:
#       if not handler(text):
#         return false
#   return true

proc required*(): ValidateHandler {.inline.} =
  result = proc(text: string): bool =
    text.len != 0
