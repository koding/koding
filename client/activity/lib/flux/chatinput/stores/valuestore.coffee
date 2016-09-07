actions         = require 'activity/flux/chatinput/actions/actiontypes'
KodingFluxStore = require 'app/flux/base/store'
immutable       = require 'immutable'

###*
 * Store to handle current chat input value
###
module.exports = class ChatInputValueStore extends KodingFluxStore

  @getterPath = 'ChatInputValueStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.SET_CHAT_INPUT_VALUE, @setValue


  ###*
   * It updates value for a given channelId and stateId
   *
   * @param {immutable.Map} currentState
   * @param {object} payload
   * @param {string} payload.channelId
   * @param {string} payload.stateId
   * @param {string} payload.value
   * @return {immutable.Map} nextState
  ###
  setValue: (currentState, { channelId, stateId, value }) ->

    currentState.set channelId, immutable.Map()  unless  currentState.get channelId
    currentState.setIn [channelId, stateId], value
