emojify = require 'emojify.js'

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

renderEmojiIcon = (emoji, emojiName) ->

  element = document.createElement 'span'
  element.className = 'emoji-wrapper'

  if emojiName in IMAGE_EMOJIS
    imagePath = 'https://s3.amazonaws.com/koding-cdn/emojis/'
    element.innerHTML = "<img src='#{imagePath}#{emojiName}.png' class='emoji' title='#{emoji}' />"
  else
    element.innerHTML = "<span class='emoji-sprite emoji-#{emojiName}' title='#{emoji}' />"

  return element


module.exports = renderEmojis = (element) -> emojify.run element, renderEmojiIcon

