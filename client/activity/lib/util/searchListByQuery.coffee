###*
 * This finctions searches for items in the list by given query
 * using the rule:
 * - if query length < 3, it search for items which start with query
 * - otherwise, it searches for items which contain query in any place of the text
###
module.exports = searchListByQuery = (list, query) ->

  isBeginningMatch = query.length < 3

  result = list.filter (item) ->
    index = item.indexOf(query)
    if isBeginningMatch then index is 0 else index > -1

