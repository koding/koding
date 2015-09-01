actions         = require 'activity/flux/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
immutable       = require 'immutable'

###*
 * Store to handle channels visibility flags
###
module.exports = class ChatInputChannelsVisibilityStore extends KodingFluxStore

  @getterPath = 'ChatInputChannelsVisibilityStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.SET_CHAT_INPUT_CHANNELS_VISIBILITY, @setVisibility


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

