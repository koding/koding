actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
toImmutable     = require 'app/util/toImmutable'

###*
 * Store to contain common emoji list visibility
###
module.exports = class CommonEmojiListVisibilityStore extends KodingFluxStore

  @getterPath = 'CommonEmojiListVisibilityStore'

  getInitialState: -> no


  initialize: ->

    @on actions.SET_COMMON_EMOJI_LIST_VISIBILITY, @setVisibility


  ###*
   * Handler of SET_COMMON_EMOJI_LIST_VISIBILITY action
   * It updates current visible flag with a given value
   *
   * @param {Immutable.Map} currentState
   * @param {object} payload
   * @param {bool} payload.visible
   * @return {bool} nextState
  ###
  setVisibility: (currentState, { visible }) -> visible

