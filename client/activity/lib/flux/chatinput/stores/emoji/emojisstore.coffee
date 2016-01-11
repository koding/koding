kd              = require 'kd'
immutable       = require 'immutable'
KodingFluxStore = require 'app/flux/base/store'
toImmutable     = require 'app/util/toImmutable'
emojisKeywords  = require 'emojis-keywords'

###*
 * Store to contain the whole list of available emojis.
 * Initial list of emojis is taken from emojis-keywords package.
###
module.exports = class EmojisStore extends KodingFluxStore

  @getterPath = 'EmojisStore'

  getInitialState: ->

    toImmutable emojisKeywords
