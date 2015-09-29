actions         = require 'activity/flux/chatinput/actions/actiontypes'
KodingFluxStore = require 'app/flux/store'
immutable       = require 'immutable'

module.exports = class ChatInputCommandsVisibilityStore extends KodingFluxStore

  @getterPath = 'ChatInputCommandsVisibilityStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.SET_CHAT_INPUT_COMMANDS_VISIBILITY, @setVisibility


  setVisibility: (currentState, { stateId, visible }) ->

    currentState.set stateId, visible

