kd              = require 'kd'
immutable       = require 'immutable'
KodingFluxStore = require 'app/flux/base/store'
toImmutable     = require 'app/util/toImmutable'
emojisKeywords  = require 'emojis-keywords'
emojiCategories = require 'emoji-shortnames'

###*
 * Store to handle a list of emoji categories and related emojis
###
module.exports = class EmojiCategoriesStore extends KodingFluxStore

  @getterPath = 'EmojiCategoriesStore'

  ###*
   * Store data is built based on categories list taken from emoji-shortnames package.
   * Emojis which do not exist in emojisKeywords list are filtered out.
   * Emojis which exist in emojisKeywords and do not exist in
   * emoji-shortnames are put to custom category
  ###
  getInitialState: ->

    data = []
    for category of emojiCategories
      data.push { category, emojis : [] }
    data.push { category : 'custom', emojis : [] }

    for emoji in emojisKeywords
      category = helper.getCategoryForEmoji emoji
      categoryItem = data.filter((item) -> item.category is category)[0]
      categoryItem.emojis.push emoji

    # clear empty categories
    result = []
    result.push categoryItem for categoryItem in data when categoryItem.emojis.length > 0

    toImmutable result


  helper =

    getCategoryForEmoji: (emoji) ->

      for category, emojis of emojiCategories
        return category  if emojis.indexOf(":#{emoji}:") > -1

      return 'custom'

