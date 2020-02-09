import ../../src/prologue

import controllers

let urlPatterns* = @[
  pattern("/todo", todoList),
  pattern("/new", newItem),
  pattern("/edit/{id}", editItem),
  pattern("/item/{item}", showItem)
]