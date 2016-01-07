actions         = require 'activity/flux/chatinput/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'
toImmutable     = require 'app/util/toImmutable'
immutable       = require 'immutable'

###*
 * Store to handle emoji usage counts
###
module.exports = class EmojiUsageCountsStore extends KodingFluxStore

  @getterPath = 'EmojiUsageCountsStore'

  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.SET_EMOJI_USAGE_COUNT,       @setUsageCount
    @on actions.INCREMENT_EMOJI_USAGE_COUNT, @incrementUsageCount


  ###*
   * Handler of SET_EMOJI_USAGE_COUNT action
   * It sets usage count for a given emoji
   *
   * @param {Immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.emoji
   * @param {number} payload.count
   * @return {Immutable.Map} nextState
  ###
  setUsageCount: (currentState, { emoji, count }) ->

    currentState.set emoji, count


  ###*
   * Handler of INCREMENT_EMOJI_USAGE_COUNT action
   * It increments usage count for a given emoji
   *
   * @param {Immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.emoji
   * @return {Immutable.Map} nextState
  ###
  incrementUsageCount: (currentState, { emoji }) ->

    count = currentState.get(emoji) ? 0
    currentState.set emoji, count + 1
