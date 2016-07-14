
module.exports = (str) ->
  str.replace '-', ' '
  .replace /(?:^\w|[A-Z]|\b\w|\s)/g, (match, index) ->
    return ''  if +match is 0

    return if index is 0 then match.toLowerCase() else match.toUpperCase()
