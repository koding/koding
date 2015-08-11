actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'

###*
 * Store to contain common emoji list flags
###
module.exports = class CommonEmojiListFlagsStore extends KodingFluxStore

  @getterPath = 'CommonEmojiListFlagsStore'

  getInitialState: -> toImmutable { visible : no }


  initialize: ->

    @on actions.SET_COMMON_EMOJI_LIST_VISIBILITY, @setVisibility
    @on actions.RESET_COMMON_EMOJI_LIST_FLAGS, @reset


  ###*
   * Handler of SET_COMMON_EMOJI_LIST_VISIBILITY action
   * It updates visible flag in store state with a given value
   *
   * @param {Immutable.Map} currentState
   * @param {object} payload
   * @param {bool} payload.visible
   * @return {Immutable.Map} nextState
  ###
  setVisibility: (currentState, { visible }) ->

    currentState.set 'visible', visible


  ###*
   * Handler of RESET_COMMON_EMOJI_LIST_FLAGS action
   * It resets current store state to initial state
   *
   * @param {Immutable.Map} currentState
   * @return {Immutable.Map} nextState
  ###
  reset: (currentState) ->

    currentState.set 'visible', no