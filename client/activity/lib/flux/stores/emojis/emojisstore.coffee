kd              = require 'kd'
immutable       = require 'immutable'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'
emojiList       = require('emojis-keywords')

module.exports = class EmojisStore extends KodingFluxStore

  @getterPath = 'EmojisStore'

  getInitialState: -> toImmutable emojiList