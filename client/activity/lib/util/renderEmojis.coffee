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

module.exports = renderEmojis = (element, showTooltip = yes) ->

  emojify.run element, (emoji, emojiName) ->
    element = document.createElement 'span'
    element.className = 'emoji-wrapper'

    titleAttr = if showTooltip then "title='#{emoji}'" else ''

    if emojiName in IMAGE_EMOJIS
      imagePath = 'https://s3.amazonaws.com/koding-cdn/emojis/'
      element.innerHTML = "<img src='#{imagePath}#{emojiName}.png' class='emoji' #{titleAttr} />"
    else
      element.innerHTML = "<span class='emoji-sprite emoji-#{emojiName}' #{titleAttr} />"

    return element
