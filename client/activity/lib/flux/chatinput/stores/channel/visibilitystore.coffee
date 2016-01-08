actions         = require 'activity/flux/chatinput/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'
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
