React = require 'kd-react'

###*
 * Searches for specified query in the word and wraps it with <strong> tags.
 * Highlighting is performed according to specified options. Query can be highlighted:
 * - if it's at the beginning of the word (options.isBeginningMatch is yes)
 * - if it's in the middle of the word (options.isMiddleMatch is yes)
 * - if it's anywhere in the word (no options are specified)
 *
 * @param {string} word
 * @param {string} query
 * @param {object} options
 * @return {string|React.Component}
###
module.exports = highlightQueryInWord = (word, query, options = {}) ->

  return word  unless word and query

  index = word.toLowerCase().indexOf query.toLowerCase()

  { isMiddleMatch, isBeginningMatch } = options

  return word  if index is -1
  return word  if isMiddleMatch and index is 0
  return word  if isBeginningMatch and index > 0

  <span>
    {word.substring 0, index}
    <strong>{word.substr index, query.length}</strong>
    {word.substring index + query.length}
  </span>
