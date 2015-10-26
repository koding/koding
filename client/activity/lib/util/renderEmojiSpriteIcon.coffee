module.exports = renderEmojiSpriteIcon = (emoji, emojiName) ->
  span = document.createElement 'span'
  span.className = "emojiSpriteIcon emoji-#{emojiName}"
  return span

