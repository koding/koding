actions         = require 'activity/flux/chatinput/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'
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
   * It updates visible flag for a given stateId
   *
   * @param {Immutable.Map} currentState
   * @param {object} payload
   * @param {bool} payload.stateId
   * @param {bool} payload.visible
   * @return {Immutable.Map} nextState
  ###
  setVisibility: (currentState, { stateId, visible }) ->

    currentState.set stateId, visible

