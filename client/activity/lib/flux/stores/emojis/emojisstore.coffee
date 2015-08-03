kd              = require 'kd'
immutable       = require 'immutable'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'
emojisKeywords  = require 'emojis-keywords'

###*
 * Store to contain the whole list of available emojis.
 * Initial list of emojis is taken from emojis-keywords package.
 * Some of emojis are not handled by emojify library which draws
 * emoji icons on the page. That's why those emojis are put to
 * SKIPPED_EMOJIES array and not included in the store
###
module.exports = class EmojisStore extends KodingFluxStore

  SKIPPED_EMOJIES = [
    'back'
    'black_medium_small_square'
    'black_medium_square'
    'black_small_square'
    'package'
    'sparkle'
    'white_medium_small_square'
    'white_medium_square'
    'white_small_square'
  ]

  @getterPath = 'EmojisStore'

  getInitialState: ->

    emojiList = emojisKeywords.filter (emoji) ->
      return SKIPPED_EMOJIES.indexOf(emoji) is -1

    toImmutable emojiList