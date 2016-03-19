htmlencode = require 'htmlencode'
shortenText = require './shortenText'

module.exports = (text, l = 500) ->
  shortenedText = shortenText text,
    minLength : l
    maxLength : l + Math.floor(l / 10)
    suffix    : ''

  # log "[#{text.length}:#{htmlencode.htmlEncode(text).length}/#{shortenedText.length}:#{htmlencode.htmlEncode(shortenedText).length}]"
  text = if htmlencode.htmlEncode(text).length > htmlencode.htmlEncode(shortenedText).length
    morePart = "<span class='collapsedtext hide'>"
    morePart += "<a href='#' class='more-link' title='Show more...'><i></i></a>"
    morePart += htmlencode.htmlEncode(text).substr htmlencode.htmlEncode(shortenedText).length
    morePart += '</span>'
    htmlencode.htmlEncode(shortenedText) + morePart
  else
    htmlencode.htmlEncode shortenedText
