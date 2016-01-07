###*
 * Finds a name which begins from the specified query
 * in the list of specified names. If name is found,
 * function returns it.
 * Usually this function is used to check if data item
 * can be selected in search especially if its name consists of
 * multiple parts
 *
 * @param {array} names
 * @param {string} query
 * @return {string}
###
module.exports = findNameByQuery = (names, query) ->

  for name in names when name?
    return name if name.toLowerCase().indexOf(query) is 0
