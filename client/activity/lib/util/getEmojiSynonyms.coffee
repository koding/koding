EMOJI_SYNONYMS = [
  [ 'hankey', 'poop', 'shit' ]
  [ 'hand', 'raised_hand' ]
  [ '+1', 'thumbsup', 'plus1' ]
  [ '-1', 'thumbsdown' ]
  [ 'facepunch', 'punch' ]
  [ 'shirt', 'tshirt' ]
  [ 'car', 'red_car' ]
  [ 'memo', 'pencil' ]
  [ 'exclamation', 'heavy_exclamation_mark' ]
  [ 'laughing', 'satisfied' ]
]

module.exports = getEmojiSynonyms = (emoji) ->

  for synonyms in EMOJI_SYNONYMS
    return synonyms  if synonyms.indexOf(emoji) > -1

