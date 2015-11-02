module.exports = findNameByQuery = (names, query) ->

  for name in names when name?
    return name if name.toLowerCase().indexOf(query) is 0