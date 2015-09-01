actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'
immutable       = require 'immutable'

###*
 * Store to contain common emoji list visibility flags
###
module.exports = class CommonEmojiListVisibilityStore extends KodingFluxStore

  @getterPath = 'CommonEmojiListVisibilityStore'

  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.SET_COMMON_EMOJI_LIST_VISIBILITY, @setVisibility


  ###*
   * Handler of SET_COMMON_EMOJI_LIST_VISIBILITY action
   * It updates visible flag for a given action initiator
   *
   * @param {Immutable.Map} currentState
   * @param {object} payload
   * @param {bool} payload.initiatorId
   * @param {bool} payload.visible
   * @return {Immutable.Map} nextState
  ###
  setVisibility: (currentState, { initiatorId, visible }) ->

    currentState.set initiatorId, visible

