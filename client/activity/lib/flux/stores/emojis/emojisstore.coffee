kd              = require 'kd'
immutable       = require 'immutable'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'
emojisKeywords  = require 'emojis-keywords'

module.exports = class EmojisStore extends KodingFluxStore

  SKIPPED_EMOGIES = [
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
      return SKIPPED_EMOGIES.indexOf(emoji) is -1

    toImmutable emojiList