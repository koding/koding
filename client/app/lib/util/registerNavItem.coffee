globals = require 'globals'

module.exports = (itemData) ->
  unless globals.navItemIndex[itemData.title]
    globals.navItemIndex[itemData.title] = itemData
    globals.navItems.push itemData
    return true
  return false
