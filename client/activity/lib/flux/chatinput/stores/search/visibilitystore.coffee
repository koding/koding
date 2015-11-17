actions         = require 'activity/flux/chatinput/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'
immutable       = require 'immutable'

###*
 * Store to handle chat input search visibility flags
###
module.exports = class ChatInputSearchVisibilityStore extends KodingFluxStore

  @getterPath = 'ChatInputSearchVisibilityStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.SET_CHAT_INPUT_SEARCH_VISIBILITY, @setVisibility


  ###*
   * It updates visibility flag for a given stateId
   *
   * @param {immutable.Map} currentState
   * @param {object} payload
   * @param {bool} payload.stateId
   * @param {bool} payload.visible
   * @return {immutable.Map} nextState
  ###
  setVisibility: (currentState, { stateId, visible }) ->

    currentState.set stateId, visible

