formatBlockquotes = require './formatBlockquotes'

positionAnchor = 'CURRENT-POSITION-ANCHOR'

module.exports = isWithinCodeBlock = (text, position) ->

  text = text.substring(0, position) + positionAnchor + text.substring(position)
  text = formatBlockquotes text

  regExp = new RegExp "(`|```)[^`]+#{positionAnchor}[^`]*\\1"

  return regExp.test text
