React = require 'kd-react'

module.exports = renderHighlightedText = (text, query, options = {}) ->

  return text  unless text and query

  index = text.toLowerCase().indexOf query.toLowerCase()

  { isMiddleMatch, isBeginningMatch } = options

  return text  if index is -1
  return text  if isMiddleMatch and index is 0
  return text  if isBeginningMatch and index > 0

  <span>
    {text.substring 0, index}
    <strong>{text.substr index, query.length}</strong>
    {text.substring index + query.length}
  </span>

