# Helper function to calculate a value
# of list selected index getter.
# It gets the list and list stored index
# and reduce index to the value which is >= 0
# and < list.size
module.exports = calculateListSelectedIndex = (list, currentIndex) ->

  return -1  unless list and list.size > 0

  { size } = list

  index = currentIndex ? 0
  unless 0 <= index < size
    index = index % size
    index += size  if index < 0

  return index
