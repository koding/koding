textHelpers       = require 'activity/util/textHelpers'
helpers           = require '../helpers'
isWithinCodeBlock = require 'app/util/isWithinCodeBlock'
EmojiDropbox      = require '../emojidropbox'
formatEmojiName   = require 'activity/util/formatEmojiName'
EmojiActions      = require 'activity/flux/chatinput/actions/emoji'

module.exports = EmojiToken =

  extractQuery: (value, position) ->

    return  if not value or isWithinCodeBlock value, position

    currentWord = textHelpers.getWordByPosition value, position
    return  unless currentWord and currentWord.length > 2

    matchResult = currentWord.match /^\:([^:]+)$/
    return matchResult[1]  if matchResult


  getConfig: ->

    return {
      component            : EmojiDropbox
      getters              :
        items              : 'dropboxEmojis'
        selectedIndex      : 'emojisSelectedIndex'
        selectedItem       : 'emojisSelectedItem'
      horizontalNavigation : yes
      submit               : ({ selectedItem, query, value, position }) ->
        EmojiActions.incrementUsageCount selectedItem

        newWord = "#{formatEmojiName selectedItem} "
        return helpers.replaceWordAtPosition value, position, newWord
    }
