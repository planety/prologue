import ../../src/prologue

import views

let urlPatterns* = @[
  pattern("/todo", todoList),
  pattern("/new", newItem),
  pattern("/edit/{id:int}", editItem),
  pattern("/item/{item:int}", showItem)
]