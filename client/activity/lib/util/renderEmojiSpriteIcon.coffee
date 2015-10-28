IMAGE_EMOJIS = [
  'broken_heart'
  'confounded'
  'flushed'
  'flowning'
  'grinning'
  'heart'
  'kissing_heart'
  'mask'
  'pensive'
  'relaxed'
  'rage'
  'smirk'
  'sob'
  'smile'
  'stuck_out_tongue_closed_eyes'
  'stuck_out_tongue_winking_eye'
  'scream'
  'wink'
]

module.exports = renderEmojiSpriteIcon = (emoji, emojiName) ->

  if emojiName in IMAGE_EMOJIS
    emojiElement = document.createElement 'img'
    emojiElement.className = 'emojiIcon'
    emojiElement.setAttribute 'src', "https://s3.amazonaws.com/koding-cdn/emojis/#{emojiName}.png"
  else
    emojiElement = document.createElement 'span'
    emojiElement.className = "emojiSpriteIcon emoji-#{emojiName}"

  emojiElement.setAttribute 'title', emoji

  return emojiElement

