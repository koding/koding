actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'

###*
 * Store to handle users visibility flag
###
module.exports = class ChatInputUsersVisibilityStore extends KodingFluxStore

  @getterPath = 'ChatInputUsersVisibilityStore'


  getInitialState: -> no


  initialize: ->

    @on actions.SET_CHAT_INPUT_USERS_VISIBILITY, @setVisibility


  ###*
   * It updates current visibility flag with a given value
   *
   * @param {number} currentState
   * @param {object} payload
   * @param {bool} payload.visible
   * @return {bool} nextState
  ###
  setVisibility: (currentState, { visible }) -> visible

