actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
immutable       = require 'immutable'

###*
 * Store to handle users visibility flags
###
module.exports = class ChatInputUsersVisibilityStore extends KodingFluxStore

  @getterPath = 'ChatInputUsersVisibilityStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.SET_CHAT_INPUT_USERS_VISIBILITY, @setVisibility


  ###*
   * It updates visibility flag for a given stateId
   *
   * @param {immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.stateId
   * @param {bool} payload.visible
   * @return {immutable.Map} nextState
  ###
  setVisibility: (currentState, { stateId, visible }) ->

    currentState.set stateId, visible

