actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
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
   * It updates visibility flag for a given action initiator
   *
   * @param {immutable.Map} currentState
   * @param {object} payload
   * @param {bool} payload.initiatorId
   * @param {bool} payload.visible
   * @return {immutable.Map} nextState
  ###
  setVisibility: (currentState, { initiatorId, visible }) ->

    currentState.set initiatorId, visible

