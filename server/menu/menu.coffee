class Menu
  
  {express} = require 'express'
    
  items = {}
  
  @register:(menu)->
    for itemDef, path in menu
      items[path] = itemDef