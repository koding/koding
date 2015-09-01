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
   * It updates visibility flag for a given action initiator
   *
   * @param {immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.initiatorId
   * @param {bool} payload.visible
   * @return {immutable.Map} nextState
  ###
  setVisibility: (currentState, { initiatorId, visible }) ->

    currentState.set initiatorId, visible

