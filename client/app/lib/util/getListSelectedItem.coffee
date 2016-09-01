# Helper function to calculate a value
# of list selected item getter.
# It gets the list and its selected index
# and returns item taken from the list by the index
module.exports = getListSelectedItem = (list, selectedIndex) ->
  return  unless list and list.size > 0
  return list.get selectedIndex
