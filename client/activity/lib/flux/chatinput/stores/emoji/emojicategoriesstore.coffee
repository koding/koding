kd                 = require 'kd'
immutable          = require 'immutable'
KodingFluxStore    = require 'app/flux/base/store'
toImmutable        = require 'app/util/toImmutable'
getSupportedEmojis = require 'activity/util/getSupportedEmojis'
emojiCategories    = require 'emoji-categories'

###*
 * Store to handle a list of emoji categories
###
module.exports = class EmojiCategoriesStore extends KodingFluxStore

  @getterPath = 'EmojiCategoriesStore'

  ###*
   * Store data is built based on categories list taken from emoji-categories package.
   * Emojis which do not exist in emojisKeywords list are filtered out.
   * Emojis which exist in emojisKeywords and do not exist in
   * emoji-categories are put to custom category
  ###
  getInitialState: ->

    data        = []
    emojiList   = getSupportedEmojis()
    otherEmojis = emojiList.slice()

    for item in emojiCategories
      emojis = []

      for emoji in item.emojis
        index = otherEmojis.indexOf emoji
        if index > -1
          emojis.push emoji
          otherEmojis.splice index, 1

      data.push { category : item.category, emojis }

    data.push { category : 'Custom', emojis : otherEmojis }

    toImmutable data
