getEmojiSynonyms = require 'activity/util/getEmojiSynonyms'

###*
 * This function finds emojis with synonyms, converts them
 * to the first synonym and removes duplicate synonyms
 *
 * @param {Immatable.List} emojis
 * @return {Immatable.List}
###
module.exports = convertEmojisWithSynonyms = (emojis) ->

  matchedSynonyms = []
  emojis = emojis.map (emoji) ->
    synonyms = getEmojiSynonyms emoji

    return emoji  unless synonyms
    return  if matchedSynonyms.indexOf(emoji) > -1

    matchedSynonyms = matchedSynonyms.concat synonyms
    return synonyms[0]

  emojis = emojis.filter Boolean

