emojisKeywords  = require 'emojis-keywords'

UNSUPPORTED_EMOJIS = [
  'frowning'
]

module.exports = getSupportedEmojis = ->

  emojisKeywords.filter (emoji) -> UNSUPPORTED_EMOJIS.indexOf(emoji) is -1
