import ../../src/prologue

import views

let urlPatterns* = @[
  pattern("/", todoList),
  pattern("/new", newItem),
  pattern("/edit/{id}", editItem),
  pattern("/item/{item}", showItem)
]
