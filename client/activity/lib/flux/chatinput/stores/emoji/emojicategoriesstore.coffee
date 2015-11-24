kd              = require 'kd'
immutable       = require 'immutable'
KodingFluxStore = require 'app/flux/base/store'
toImmutable     = require 'app/util/toImmutable'
emojisKeywords  = require 'emojis-keywords'
emojiCategories = require './emojicategories'

###*
 * Store to handle a list of emoji categories and related emojis
###
module.exports = class EmojiCategoriesStore extends KodingFluxStore

  @getterPath = 'EmojiCategoriesStore'

  getInitialState: ->

    data = []

    for item in emojiCategories
      data.push { category : item.category, emojis : [] }
    data.push { category : 'Custom', emojis : [] }

    for emoji in emojisKeywords
      categoryName = helper.getCategoryNameForEmoji emoji
      categoryItem = data.filter((item) -> item.category is categoryName)[0]
      categoryItem.emojis.push emoji

    toImmutable data


  helper =

    getCategoryNameForEmoji: (emoji) ->

      for item in emojiCategories
        return item.category  if item.emojis.indexOf(emoji) > -1

      return 'Custom'

