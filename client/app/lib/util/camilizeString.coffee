###*
   * Find empty space or -
   * Remove empty space or -
   * make Uppercase initial char of word that is found after empty space or -
   * @param {String} str
###

module.exports = (str) ->
  str.replace /(\s|\-)\w/, (match, index) ->
    return ''  if +match is 0

    match = match.substr(1)  if match.charAt(0) is ' ' or match.charAt(0) is '-'

    return if index is 0 then match.toLowerCase() else match.toUpperCase()
